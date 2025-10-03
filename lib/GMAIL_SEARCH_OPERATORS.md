# Gmail Search Operators Reference

Source: [Gmail Help - Refine searches in Gmail](https://support.google.com/mail/answer/7190?hl=en&co=GENIE.Platform%3DDesktop)

You can use words or symbols called search operators to filter your Gmail search results. You can also combine operators to filter your results even more.

## How to Use Search Operators

1. On your computer, go to Gmail.
2. At the top, click the search box.
3. Enter a search operator.

### Tips

- After you search, you can use the results to set up a filter for these messages.
- When using numbers as part of your query, a space or a dash (-) will separate a number while a dot (.) will be a decimal. For example, 01.2047-100 is considered 2 numbers: 01.2047 and 100.

## Search Operators

| Search Operator | Description | Example |
|---|---|---|
| `from:` | Find emails sent from a specific person. | `from:me`<br>`from:amy@example.com` |
| `to:` | Find emails sent to a specific person. | `to:me`<br>`to:john@example.com` |
| `cc:`<br>`bcc:` | Find emails that include specific people in the "Cc" or "Bcc" fields. | `cc:john@example.com`<br>`bcc:david@example.com` |
| `subject:` | Find emails by a word or phrase in the subject line. | `subject:dinner`<br>`subject:anniversary party` |
| `after:`<br>`before:`<br>`older:`<br>`newer:` | Search for emails received during a certain time period. | `after:2004/04/16`<br>`after:04/16/2004`<br>`before:2004/04/18`<br>`before:04/18/2004` |
| `older_than:`<br>`newer_than:` | Search for emails older or newer than a time period. Use d (day), m (month), or y (year). | `older_than:1y`<br>`newer_than:2d` |
| `OR` or `{ }` | Find emails that match one or more of your search criteria. | `from:amy OR from:david`<br>`{from:amy from:david}` |
| `AND` | Find emails that match all of your search criteria. | `from:amy AND to:david` |
| `-` | Exclude emails from your search criteria. | `dinner -movie` |
| `AROUND` | Find emails with words near each other. Use the number to say how many words apart the words can be. Add quotes to find messages in which the word you put first stays first. | `holiday AROUND 10 vacation`<br>`"secret AROUND 25 birthday"` |
| `label:` | Find emails under one of your labels. | `label:friends`<br>`label:important` |
| `category:` | If you use inbox categories, find emails under one of the categories. | `category:primary`<br>`category:social`<br>`category:promotions`<br>`category:updates`<br>`category:forums`<br>`category:reservations`<br>`category:purchases` |
| `has:` | Find emails that include:<br>- Attachments<br>- Inline images<br>- YouTube videos<br>- Drive files<br>- Google Docs<br>- Google Sheets<br>- Google Slides | `has:attachment`<br>`has:youtube`<br>`has:drive`<br>`has:document`<br>`has:spreadsheet`<br>`has:presentation` |
| `list:` | Find emails from a mailing list. | `list:info@example.com` |
| `filename:` | Find emails that have attachments with a certain name or file type. | `filename:pdf`<br>`filename:homework.txt` |
| `" "` | Search for emails with an exact word or phrase. | `"dinner and movie tonight"` |
| `( )` | Group multiple search terms together. | `subject:(dinner movie)` |
| `in:anywhere` | Find emails across Gmail. This includes emails in Spam and Trash. | `in:anywhere movie` |
| `in:archive` | Search for archived messages. | `in:archive payment reminder` |
| `in:snoozed` | Find emails that you snoozed. | `in:snoozed birthday reminder` |
| `is:muted` | Find emails that you muted. | `is:muted subject:team celebration` |
| `is:` | Search for emails by their status:<br>- Important<br>- Starred<br>- Unread<br>- Read | `is:important`<br>`is:starred`<br>`is:unread`<br>`is:read` |
| `has:yellow-star`<br>`has:orange-star`<br>`has:red-star`<br>`has:purple-star`<br>`has:blue-star`<br>`has:green-star`<br>`has:red-bang`<br>`has:orange-guillemet`<br>`has:yellow-bang`<br>`has:green-check`<br>`has:blue-info`<br>`has:purple-question` | If you set up different star options, you can search for emails under a star option. | `has:yellow-star OR has:purple-question` |
| `deliveredto:` | Find emails delivered to a specific email address. | `deliveredto:username@example.com` |
| `size:`<br>`larger:`<br>`smaller:` | Find emails by their size. | `size:1000000`<br>`larger:10M` |
| `+` | Find emails that match a word exactly. | `+unicorn` |
| `rfc822msgid:` | Find emails with a specific message-id header. | `rfc822msgid:200503292@example.com` |
| `has:userlabels`<br>`has:nouserlabels` | Find emails that have or don't have a label. Labels are only added to a message, and not an entire conversation. | `has:userlabels`<br>`has:nouserlabels` |
| `label:encryptedmail` | Find emails sent with Client-side encryption. | `label:encryptedmail` |

## Additional Notes

- You can combine operators to create complex searches
- Operators work with both implicit AND (space-separated terms) and explicit AND
- Use parentheses `()` or braces `{}` to group terms and create complex queries
- Operator values can contain expressions, e.g., `from:(alice@ OR bob@)` or `from:{alice@ bob@}`

