

# EBD : Database Specification

## A4: Conceptual Data Model

The goal of this artifact is to define and represent the key entities and relationships that form the foundation of the database design. It provides a clear and structured conceptual view of the system’s data through a UML class diagram.

## A5 : Relational Schema

| ID | Relation |
|----|----------|
| R01 | user_account(<ins>id</ins>, email UK NN, name NN, password NN, join_date NN DF Today, profile_picture) |
| R02 | campaign(<ins>id</ins>, name NN, description NN, goal NN, funded NN CK funded \<= goal, start_date NN DF Today, close_date CK (close_date IS NULL OR close_date \>= start_date), end_date CK (end_date IS NULL OR (end_date \>= start_date AND (close_date IS NULL OR close_date \>= end_date))), state NN CK state IN States, creator_id -\> user.id, category_id NN -\> category.id) |
| R03 | admin(<ins>id</ins>, email UK NN, password NN) |
| R04 | oauth_account(<ins>id</ins>, provider, provider_email NN, provider_user_id NN, avatar_url, access_token, refresh_token, token_expires_at, user -\> user.id) |
| R05 | blocked_user(<ins>id</ins> -\> user.id, datetime NN, reason NN) |
| R06 | appeal(<ins>id</ins>, block -\> blocked_user.id, whining NN, datetime NN) |
| R07 | comment(<ins>id</ins>, content NN, datetime NN, author -\> user.id, campaign -\> campaign.id NN, parent -\> comment.id) |
| R08 | transaction(<ins>id</ins>, datetime NN, amount NN CK \> 0, is_valid NN DF TRUE, author -\> user.id, campaign -\> campaign.id NN) |
| R09 | category(<ins>id</ins>, name UK NN) |
| R10 | update(<ins>id</ins>, content NN, datetime NN, campaign -\> campaign.id NN) |
| R11 | resource(<ins>id</ins>, name NN, path NN, order NN, campaign -\> campaign.id, update -\> update.id) |
| R12 | notification(<ins>id</ins>, content NN, is_read NN, datetime NN DF Today) |
| R13 | notification_of_update(<ins>id</ins> -\> notification.id, update -\> update.id NN) |
| R14 | notification_of_comment(<ins>id</ins> -\> notification.id, comment -\> comment.id NN) |
| R15 | notification_of_transaction(<ins>id</ins> -\> notification.id, transaction -\> transaction.id NN) |
| R16 | owner(<ins>user</ins> -\> user.id, <ins>campaign</ins> -\> campaign.id NN) |
| R17 | follow(<ins>user</ins> -\> user.id NN, <ins>campaign</ins> -\> campaign.id NN) |

UK = Unique Key
NN = Not Null
CK = Check
DF = Default

### Domains

Today: DATE DEFAULT CURRENT_DATE
States: ENUM (‘unfunded’, ‘ongoing’, ‘completed’, ‘paused’, ‘suspended’)

### Schema Validation

**R01 – user_account**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0101a: {id} → {email, name, password, join_date, profile_picture}`  
  - `FD0101b: {email} → {id, name, password, join_date, profile_picture}`  
  

**R02 – campaign**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0102: {id} → {name, description, funded, goal, start_date, close_date, end_date, state, creator, category}`  
 

**R03 – admin**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0103a: {id} → {email, password}`  
  - `FD0103b: {email} → {id, password}`  
 

**R04 – oauth_account**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0104: {id} → {provider, provider_email, provider_user_id, avatar_url, access_token, refresh_token, token_expires_at, user}`  


**R05 – blocked_user**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0105: {id} → {datetime, reason}`  
 

**R06 – appeal**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0106: {id} → {block, whining, datetime}`  
 

**R07 – comment**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0107: {id} → {content, datetime, author, campaign, parent}`  


**R08 – transaction**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0108: {id} → {datetime, amount, is_valid, author, campaign}`  


**R09 – category**  
- **Keys:**  
  - `{id}`, `{name}`  
- **Functional Dependencies:**  
  - `FD0109a: {id} → {name}`  
  - `FD0109b: {name} → {id}`  
 

**R10 – update**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0110: {id} → {content, datetime, campaign}`  


**R11 – resource**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0111: {id} → {name, location, order, campaign, update}`  


**R12 – notification**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0112: {id} → {text, is_read, datetime}`  


**R13 – notification_of_update**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0113: {id} → {update}`  
 

**R14 – notification_of_comment**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0114: {id} → {comment}`  
 

**R15 – notification_of_transaction**  
- **Keys:**  
  - `{id}`  
- **Functional Dependencies:**  
  - `FD0115: {id} → {transaction}`  


**R16 – owner**  
- **Keys:**  
  - `{user, campaign}`  
- **Functional Dependencies:**  
  - `FD0116: {user, campaign} → ∅`  
 

**R17 – follow**  
- **Keys:**  
  - `{user, campaign}`  
- **Functional Dependencies:**  
  - `FD0117: {user, campaign} → ∅`  


## A6 : Indexes, Integrity and Populated Database

