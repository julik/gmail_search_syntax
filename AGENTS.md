# Agent Guidelines for gmail_search_syntax

This document outlines the coding standards and workflow requirements for AI agents working on the gmail_search_syntax project.

## Ruby File Standards

### Frozen String Literal
**ALWAYS** include `# frozen_string_literal: true` at the top of every Ruby file:

```ruby
# frozen_string_literal: true

class MyClass
  # ... implementation
end
```

This directive should be the very first line of every `.rb` file to ensure string immutability and improve performance.

## Documentation Standards

### Markdown Files Location
When writing step-by-step instructions, documentation, or process descriptions in Markdown format, place them in the `slop/` directory:

```
slop/
├── ARCHITECTURE.md
├── GMAIL_BEHAVIOR_COMPARISON.md
├── GMAIL_COMPATIBILITY_COMPLETE.md
└── IMPLEMENTATION_NOTES.md
```

This keeps the main project directory clean while preserving detailed documentation and implementation notes.

## Code Formatting

### StandardRB Integration
After creating or modifying any Ruby file, **ALWAYS** run StandardRB to maintain consistent formatting:

```bash
standardrb --fix /path/to/file.rb
```

This ensures:
- Consistent code style across the project
- Automatic fixing of common formatting issues
- Compliance with the project's Ruby style guide
- Uniform indentation, spacing, and syntax

### Workflow
1. Create or modify a Ruby file
2. Immediately run `standardrb --fix` on the file
3. Verify the changes are acceptable
4. Continue with development

## Project Context

This is a Ruby gem that parses Gmail's search syntax and converts it into an Abstract Syntax Tree (AST). The project includes:

- **Core parsing**: Tokenizer, parser, and AST nodes
- **SQL conversion**: SQLite and Postgres visitors for database queries
- **Comprehensive testing**: Unit and integration tests
- **Documentation**: Schema documentation and operator reference

## Key Files

- `lib/gmail_search_syntax.rb` - Main entry point
- `lib/gmail_search_syntax/parser.rb` - Core parsing logic
- `lib/gmail_search_syntax/sql_visitor.rb` - SQL generation
- `test/` - Test suite
- `SCHEMA.md` - Database schema documentation
- `slop/` - Detailed implementation documentation

## Best Practices

1. **Test Coverage**: Ensure all new functionality has corresponding tests
2. **Documentation**: Update relevant documentation when adding features
3. **Backward Compatibility**: Maintain API compatibility when possible
4. **Performance**: Consider performance implications of parsing changes
5. **Gmail Compatibility**: Verify changes against Gmail's actual search behavior

## Example Workflow

```bash
# 1. Create a new Ruby file
echo '# frozen_string_literal: true' > lib/gmail_search_syntax/new_feature.rb

# 2. Add implementation
# ... write code ...

# 3. Format with StandardRB
standardrb --fix lib/gmail_search_syntax/new_feature.rb

# 4. Create documentation if needed
echo '# Implementation Notes' > slop/NEW_FEATURE_NOTES.md

# 5. Add tests
# ... write tests ...

# 6. Run test suite
bundle exec rake test
```

Remember: Consistency in code style and documentation organization is crucial for maintaining this project's quality and readability.
