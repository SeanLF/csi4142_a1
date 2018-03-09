# My solution for Assignment 1

*Please note that my solution uses Ruby, Rails and third party libraries in order to quickly create a DB and insert from my script.*

## Pseudocode

- I use a data structure (DS) with fast insertion and searching (hashmap: `{}` or `Hash.new`)
- Idea: While iterating over your CSV rows, keep track of values seen, and use DS.num_elements + 1 as the ID when adding elements to the DS


```python
dates, shapes, locations = {}, {}, {} # hash[string of dimension value] = id_for_dimension_table
fact = [] # array of hashmaps

for row in CSV.rows:

  # --- surrogate key generation ---
  # do the following for shapes and locations too
  
  date = Date.parse(row['index of column for date'])
  dateKey = dates[date]  # check if I've encountered this date already
  
  if dateKey == nil: # have not seen this date yet
    # add it to the hash
    dates[date] = dates.size + 1 # dates.size corresponds to the number of dates seen, +1 needed so first id starts at 1
    
  # after processing the values in the row
  fact += {
    date_key: dateKey,
    shape_key: shapeKey,
    location_key: locationKey,
    duration: row['index for duration']
  }
  
# finished looping through the CSV
# dates, shapes, locations dimensions can be created using the dates,shapes,locations hashes by swapping the keys for the values
  # example
    # from dates[date_value] = id_for_that_date_value
    # to   dates[id_for_that_date_value] = date_value

# either connect to the DB and import your tables in batches
# or export each table to a CSV file
```
