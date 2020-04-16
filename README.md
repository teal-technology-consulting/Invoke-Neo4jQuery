# Invoke-Neo4jQuery
As part of our Active Directory Assessments we frequently use Bloodhound as well as the Neo4j console to run custom cypher queries. 
We wrote this little script to easily run a set of standardized queries and export the results as CSV to hand them over to our clients as part of the assessment results.

It works like this:
The script reads one or more CYPHER queries with their titles out of an inpute file. It looks for the file "neo4j_queries.json" in the same directory.
It then queries the database "neo4j" of a local instance of neo4j by using the credentials "neo4j" and "Bloodhound".
It creates one CSV file per query with the title as file name in the current directory.
Database URL, input file name, username, password and output directory can be passed to the script as parameters.
Be aware that when you have long running queries and you exit the script, the running query will still be executed by neo4j in the background.

If you want to know more about our Active Directory Assessment visit https://www.teal-consulting.de/en/2019/11/13/assume-breach/

Shout-out to "Sinister China Penguin" who published a script we used as foundation. 
