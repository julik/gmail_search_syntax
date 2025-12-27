module GmailSearchSyntax
  class Query
    attr_reader :conditions, :joins, :params, :alias_counter

    def initialize(alias_counter:)
      @conditions = []
      @joins = {}
      @params = []
      @table_aliases = {}
      @alias_counter = alias_counter
    end

    def add_condition(sql_fragment)
      @conditions << sql_fragment
    end

    def add_param(value)
      @params << value
    end

    def add_join(table_name, join_sql)
      @joins["#{table_name}_#{@joins.size}"] = join_sql
    end

    def get_table_alias(table_name, base_alias = nil)
      counter_value = @alias_counter.next
      base_alias || "#{table_name.split("_").map { |w| w[0] }.join}#{counter_value}"
    end

    def to_sql
      where_clause = @conditions.empty? ? "1 = 1" : @conditions.join(" ")
      base_query = "SELECT DISTINCT m0.id FROM messages AS m0"
      join_clause = @joins.values.join(" ")
      full_query = [base_query, join_clause, "WHERE", where_clause].reject(&:empty?).join(" ")
      [full_query, @params]
    end
  end

  class SQLiteVisitor
    def initialize(current_user_email: nil, alias_counter: (1..).each)
      @current_user_email = current_user_email
      @query = Query.new(alias_counter:)
    end

    def visit(node)
      case node
      when AST::Operator
        visit_operator(node)
      when AST::LooseWord
        visit_loose_word(node)
      when AST::ExactWord
        visit_exact_word(node)
      when AST::And
        visit_and(node)
      when AST::Or
        visit_or(node)
      when AST::Not
        visit_not(node)
      when AST::Group
        visit_group(node)
      when AST::Around
        visit_around(node)
      else
        raise "Unknown node type: #{node.class}"
      end
    end

    def to_query
      @query
    end

    private

    def visit_operator(node)
      case node.name
      when "from", "to", "cc", "bcc", "deliveredto"
        visit_address_operator(node)
      when "subject"
        visit_subject_operator(node)
      when "after", "before", "older", "newer"
        visit_date_operator(node)
      when "older_than", "newer_than"
        visit_relative_date_operator(node)
      when "label"
        visit_label_operator(node)
      when "category"
        visit_category_operator(node)
      when "has"
        visit_has_operator(node)
      when "list"
        visit_list_operator(node)
      when "filename"
        visit_filename_operator(node)
      when "in"
        visit_in_operator(node)
      when "is"
        visit_is_operator(node)
      when "size", "larger", "smaller"
        visit_size_operator(node)
      when "rfc822msgid"
        visit_rfc822msgid_operator(node)
      else
        raise "Unknown operator: #{node.name}"
      end
    end

    def visit_address_operator(node)
      address_types = case node.name
      when "from"
        ["from", "cc", "bcc"]
      when "to"
        ["to", "cc", "bcc"]
      when "cc"
        ["cc"]
      when "bcc"
        ["bcc"]
      when "deliveredto"
        ["delivered_to"]
      end

      if node.value.is_a?(AST::Or) || node.value.is_a?(AST::And) || node.value.is_a?(AST::Group)
        sub_visitor = self.class.new(current_user_email: @current_user_email, alias_counter: @query.alias_counter)
        sub_visitor.visit(node.value)
        sub_query = sub_visitor.to_query

        alias_name = @query.get_table_alias("message_addresses", "ma#{@query.get_table_alias("message_addresses").gsub(/\D/, "")}")
        @query.add_join(alias_name, "INNER JOIN message_addresses AS #{alias_name} ON m0.id = #{alias_name}.message_id")

        address_type_conditions = address_types.map { |type| "#{alias_name}.address_type = ?" }
        address_types.each { |type| @query.add_param(type) }

        email_conditions = sub_query.conditions.map { |cond| cond.gsub(/\bma\d+\.email_address\b/, "#{alias_name}.email_address") }
        sub_query.params.each { |param| @query.add_param(param) }

        @query.add_condition("((#{address_type_conditions.join(" OR ")}) AND (#{email_conditions.join(" ")}))")
      else
        value = node.value.is_a?(String) ? node.value : node.value.value

        value = @current_user_email if value == "me" && @current_user_email

        alias_name = @query.get_table_alias("message_addresses", "ma#{@query.get_table_alias("message_addresses").gsub(/\D/, "")}")
        @query.add_join(alias_name, "INNER JOIN message_addresses AS #{alias_name} ON m0.id = #{alias_name}.message_id")

        address_type_conditions = address_types.map { |type| "#{alias_name}.address_type = ?" }
        address_types.each { |type| @query.add_param(type) }

        email_condition = build_string_match_condition("#{alias_name}.email_address", value)

        @query.add_condition("((#{address_type_conditions.join(" OR ")}) AND #{email_condition})")
      end
    end

    def visit_subject_operator(node)
      if node.value.is_a?(AST::Or) || node.value.is_a?(AST::And) || node.value.is_a?(AST::Group)
        sub_visitor = self.class.new(current_user_email: @current_user_email, alias_counter: @query.alias_counter)
        sub_visitor.visit(node.value)
        sub_query = sub_visitor.to_query

        subject_conditions = sub_query.conditions.map { |cond|
          cond.gsub("messages_fts MATCH ?", "m0.subject LIKE ?")
            .gsub("(1 = 1)", "m0.subject LIKE ?")
        }
        sub_query.params.each { |param| @query.add_param("%#{param}%") }

        @query.add_condition("(#{subject_conditions.join(" ")})")
      else
        value = node.value.is_a?(String) ? node.value : node.value.value
        @query.add_param("%#{value}%")
        @query.add_condition("m0.subject LIKE ?")
      end
    end

    def visit_date_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value
      date = parse_date(value)
      @query.add_param(date)

      case node.name
      when "after", "newer"
        @query.add_condition("m0.internal_date > ?")
      when "before", "older"
        @query.add_condition("m0.internal_date < ?")
      end
    end

    def visit_relative_date_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value
      modifier = parse_relative_time(value)
      @query.add_param(modifier)

      case node.name
      when "older_than"
        @query.add_condition("m0.internal_date < datetime('now', ?)")
      when "newer_than"
        @query.add_condition("m0.internal_date > datetime('now', ?)")
      end
    end

    def visit_label_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value

      alias_name = @query.get_table_alias("message_labels", "ml")
      label_alias = @query.get_table_alias("labels", "l")

      @query.add_join("#{alias_name}_#{label_alias}",
        "INNER JOIN message_labels AS #{alias_name} ON m0.id = #{alias_name}.message_id " \
        "INNER JOIN labels AS #{label_alias} ON #{alias_name}.label_id = #{label_alias}.id")

      @query.add_param(value)
      @query.add_condition("#{label_alias}.name = ?")
    end

    def visit_category_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value
      @query.add_param(value)
      @query.add_condition("m0.category = ?")
    end

    def visit_has_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value

      case value
      when "attachment", "youtube", "drive", "document", "spreadsheet", "presentation"
        @query.add_condition("m0.has_#{value} = 1")
      when "yellow-star", "orange-star", "red-star", "purple-star", "blue-star", "green-star",
           "red-bang", "orange-guillemet", "yellow-bang", "green-check", "blue-info", "purple-question"
        column_name = value.tr("-", "_")
        @query.add_condition("m0.has_#{column_name} = 1")
      when "userlabels"
        alias_name = @query.get_table_alias("message_labels", "ml")
        label_alias = @query.get_table_alias("labels", "l")

        @query.add_join("#{alias_name}_#{label_alias}_userlabels",
          "INNER JOIN message_labels AS #{alias_name} ON m0.id = #{alias_name}.message_id " \
          "INNER JOIN labels AS #{label_alias} ON #{alias_name}.label_id = #{label_alias}.id")

        @query.add_condition("#{label_alias}.is_system_label = 0")
      when "nouserlabels"
        @query.add_condition("NOT EXISTS (SELECT 1 FROM message_labels AS ml " \
          "INNER JOIN labels AS l ON ml.label_id = l.id " \
          "WHERE ml.message_id = m0.id AND l.is_system_label = 0)")
      else
        raise "Unknown has: value: #{value}"
      end
    end

    def visit_list_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value
      condition = build_string_match_condition("m0.mailing_list", value)
      @query.add_condition(condition)
    end

    def visit_filename_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value

      alias_name = @query.get_table_alias("attachments", "a")
      @query.add_join(alias_name, "INNER JOIN attachments AS #{alias_name} ON m0.id = #{alias_name}.message_id")

      if value.include?(".")
        @query.add_param(value)
        @query.add_condition("#{alias_name}.filename = ?")
      else
        @query.add_param("%.#{value}")
        @query.add_param("#{value}%")
        @query.add_condition("(#{alias_name}.filename LIKE ? OR #{alias_name}.filename LIKE ?)")
      end
    end

    def visit_in_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value

      case value
      when "anywhere"
        nil
      when "inbox"
        @query.add_condition("m0.in_inbox = 1")
      when "archive"
        @query.add_condition("m0.in_archive = 1")
      when "snoozed"
        @query.add_condition("m0.in_snoozed = 1")
      when "spam"
        @query.add_condition("m0.in_spam = 1")
      when "trash"
        @query.add_condition("m0.in_trash = 1")
      else
        raise "Unknown in: value: #{value}"
      end
    end

    def visit_is_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value

      case value
      when "important"
        @query.add_condition("m0.is_important = 1")
      when "starred"
        @query.add_condition("m0.is_starred = 1")
      when "unread"
        @query.add_condition("m0.is_unread = 1")
      when "read"
        @query.add_condition("m0.is_read = 1")
      when "muted"
        @query.add_condition("m0.is_muted = 1")
      else
        raise "Unknown is: value: #{value}"
      end
    end

    def visit_size_operator(node)
      value = node.value
      size_bytes = parse_size(value)
      @query.add_param(size_bytes)

      case node.name
      when "size"
        @query.add_condition("m0.size_bytes = ?")
      when "larger"
        @query.add_condition("m0.size_bytes > ?")
      when "smaller"
        @query.add_condition("m0.size_bytes < ?")
      end
    end

    def visit_rfc822msgid_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value
      @query.add_param(value)
      @query.add_condition("m0.rfc822_message_id = ?")
    end

    def visit_loose_word(node)
      # Word boundary matching - the value should appear as a complete word/token
      # We use LIKE with word boundaries: spaces, start/end of string
      value = node.value
      @query.add_param(value)
      @query.add_param("#{value} %")
      @query.add_param("% #{value}")
      @query.add_param("% #{value} %")
      @query.add_condition("((m0.subject = ? OR m0.subject LIKE ? OR m0.subject LIKE ? OR m0.subject LIKE ?) OR (m0.body = ? OR m0.body LIKE ? OR m0.body LIKE ? OR m0.body LIKE ?))")
      @query.add_param(value)
      @query.add_param("#{value} %")
      @query.add_param("% #{value}")
      @query.add_param("% #{value} %")
    end

    def visit_exact_word(node)
      # ExactWord matching - the value can appear anywhere in the text
      @query.add_param("%#{node.value}%")
      @query.add_param("%#{node.value}%")
      @query.add_condition("(m0.subject LIKE ? OR m0.body LIKE ?)")
    end

    def visit_and(node)
      conditions = []
      node.operands.each do |operand|
        sub_visitor = self.class.new(current_user_email: @current_user_email, alias_counter: @query.alias_counter)
        sub_visitor.visit(operand)
        sub_query = sub_visitor.to_query

        sub_query.joins.each { |key, join_sql| @query.add_join(key, join_sql) }
        sub_query.params.each { |param| @query.add_param(param) }

        conditions << if sub_query.conditions.length > 1
          "(#{sub_query.conditions.join(" ")})"
        else
          sub_query.conditions.first
        end
      end

      @query.add_condition("(#{conditions.join(" AND ")})")
    end

    def visit_or(node)
      conditions = []
      node.operands.each do |operand|
        sub_visitor = self.class.new(current_user_email: @current_user_email, alias_counter: @query.alias_counter)
        sub_visitor.visit(operand)
        sub_query = sub_visitor.to_query

        sub_query.joins.each { |key, join_sql| @query.add_join(key, join_sql) }
        sub_query.params.each { |param| @query.add_param(param) }

        conditions << if sub_query.conditions.length > 1
          "(#{sub_query.conditions.join(" ")})"
        else
          sub_query.conditions.first
        end
      end

      @query.add_condition("(#{conditions.join(" OR ")})")
    end

    def visit_not(node)
      sub_visitor = self.class.new(current_user_email: @current_user_email, alias_counter: @query.alias_counter)
      sub_visitor.visit(node.child)
      sub_query = sub_visitor.to_query

      sub_query.joins.each { |key, join_sql| @query.add_join(key, join_sql) }
      sub_query.params.each { |param| @query.add_param(param) }

      combined_condition = (sub_query.conditions.length > 1) ?
        "(#{sub_query.conditions.join(" ")})" :
        sub_query.conditions.first

      @query.add_condition("NOT #{combined_condition}")
    end

    def visit_group(node)
      if node.children.length == 1
        visit(node.children.first)
      else
        conditions = []
        node.children.each do |child|
          sub_visitor = self.class.new(current_user_email: @current_user_email, alias_counter: @query.alias_counter)
          sub_visitor.visit(child)
          sub_query = sub_visitor.to_query

          sub_query.joins.each { |key, join_sql| @query.add_join(key, join_sql) }
          sub_query.params.each { |param| @query.add_param(param) }

          conditions << sub_query.conditions.join(" ")
        end

        @query.add_condition("(#{conditions.join(" AND ")})")
      end
    end

    def visit_around(node)
      @query.add_condition("(1 = 0)")
    end

    def build_string_match_condition(column_name, value)
      if value.start_with?("@")
        @query.add_param("%#{value}")
        "#{column_name} LIKE ?"
      elsif value.end_with?("@")
        @query.add_param("#{value}%")
        "#{column_name} LIKE ?"
      else
        @query.add_param(value)
        "#{column_name} = ?"
      end
    end

    def parse_date(value)
      value.tr("/", "-")
    end

    def parse_relative_time(value)
      match = value.match(/^(\d+)([dmy])$/)
      return value unless match

      amount = match[1]
      unit = case match[2]
      when "d" then "days"
      when "m" then "months"
      when "y" then "years"
      end

      "-#{amount} #{unit}"
    end

    def parse_size(value)
      if value.is_a?(Integer)
        return value
      end

      if value =~ /^(\d+)([KMG])$/i
        number = $1.to_i
        unit = $2.upcase

        case unit
        when "K" then number * 1024
        when "M" then number * 1024 * 1024
        when "G" then number * 1024 * 1024 * 1024
        end
      else
        value.to_i
      end
    end
  end

  class PostgresVisitor < SQLiteVisitor
    # Override to use PostgreSQL's NOW() and INTERVAL syntax
    def visit_relative_date_operator(node)
      value = node.value.is_a?(String) ? node.value : node.value.value
      interval = parse_relative_time_postgres(value)
      @query.add_param(interval)

      case node.name
      when "older_than"
        @query.add_condition("m0.internal_date < (NOW() - ?::interval)")
      when "newer_than"
        @query.add_condition("m0.internal_date > (NOW() - ?::interval)")
      end
    end

    private

    def parse_relative_time_postgres(value)
      match = value.match(/^(\d+)([dmy])$/)
      return value unless match

      amount = match[1]
      unit = case match[2]
      when "d" then "days"
      when "m" then "months"
      when "y" then "years"
      end

      "#{amount} #{unit}"
    end
  end
end
