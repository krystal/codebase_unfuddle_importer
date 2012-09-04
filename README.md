##Unfuddle to Codebase Importer

This script will import your tickets and attachments from Unfuddle to Codebase.

###Requirements 
Tested on Ruby 1.9.2p318. Requires JSON and multipart-post gems. To install run:

```
gem install json
gem install multipart-post
```

###Usage 
You should have all users involved in your discussions created in Codebase prior to running this script. The importer will attempt to make a match between users based upon their primary email addresses. If no match is found for that user, the name will still be copied correctly, but there will be no link to that user, and entries will show up as "Unknown Entity" in your Codebase activity feed.

Edit the script and enter your Unfuddle and Codebase credentials in the appropriate constants.



Execute unfuddle.rb:
```
ruby -rubygems unfuddle.rb
```
The importer will retrieve your Unfuddle statuses and priorities and give you a snippet of code to paste back in to unfuddle.rb.

To do this, select all the text from the terminal. Copy this, then go to your edit window. Note the line that says "Replace the five lines below with the code given to you.". Delete 5 lines below this, then paste your copied code in it's place.

After you've done this, you're unfuddle.rb should look a little like this:

````ruby
# code...

## Codebase status New has an ID of 1468539
## Codebase status Accepted has an ID of 1468540
## Codebase status In Progress has an ID of 1468541
## Codebase status Completed has an ID of 1468542
## Codebase status Invalid has an ID of 1468543

@status_mapping = {
  'new' => {
    :codebase_id => ''
    },
  'unaccepted' => {
    :codebase_id => ''
  },
  'reassigned' => {
    :codebase_id => ''
  },
  'reopened' => {
    :codebase_id => ''
  },
  'accepted' => {
    :codebase_id => ''
  },
  'resolved' => {
    :codebase_id => ''
  },
  'closed' => {
    :codebase_id => ''
  }
}

## Codebase priority Critical has an ID of 1468545
## Codebase priority High has an ID of 1468546
## Codebase priority Normal has an ID of 1468547
## Codebase priority Low has an ID of 1468548

@priority_mapping = {
  '1' => {
    :codebase_id => ''
    },
  '2' => {
    :codebase_id => ''
  },
  '3' => {
    :codebase_id => ''
  },
  '4' => {
    :codebase_id => ''
  },
  '5' => {
    :codebase_id => ''
  }
}

# code...
````

Now you need to enter the Codebase ID for each status and priority.

Once you have done this, save unfuddle.rb. In your command window, rerun unfuddle.rb. Type y and hit enter to resume importing your tickets.

The importer will detect that you have pasted in the code it gave you earlier. If it presents the code snippet to you again, re-read this section to ensure you have pasted the code in correctly and saved the file.