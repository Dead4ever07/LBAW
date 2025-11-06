# EBD : Database Specification

## A4: Conceptual Data Model

The goal of this artifact is to define and represent the key entities and relationships that form the foundation of the database design. It provides a clear and structured conceptual view of the system’s data through a UML class diagram.

### 4.1 Class Diagram

![A4](uploads/9456879d587c07f19a5ff7b7efc0e9e1/A4.drawio.png)


### 4.2 Additional Business Rules

Additional business rules or restrictions that cannot be conveyed directly through the UML class diagram are described in this section. 

| Identifier | Name | Description |
|------------|------|-------------|
| BR1 | Owner Donation Restriction | A campaign owner cannot contribute (donate) to their own campaign. |
| BR2 | Campaign Deletion Policy | A campaign can only be deleted when its state is *unfunded*; it cannot be deleted in *ongoing*, *paused*, *completed* or *suspended* states. |
| BR3 | User Account Deletion Behavior | When a user account is deleted:<br>- Associated OAuthAccounts and Notifications are deleted (*cascade*).<br>- The `user_id` field in Transactions, Comments, and Campaigns is set to *NULL*.<br>- Transactions linked to campaigns that are not *completed* become automatically invalid.<br>- If a campaign loses all owners, BR4 applies. |
| BR4 | Owner Loss and Auto-Suspension | If a campaign has no remaining owners (for example, after account deletion), its state automatically changes to *suspended*. |
| BR5 | Campaign State Behavior | The allowed actions depend on the campaign’s current state:<br>- Unfunded: owner may delete; users may donate and comment.<br>- Ongoing: owner cannot delete; users may donate and comment.<br>- Completed: owner cannot delete; users cannot donate but may comment. The *completed* state is final and cannot be changed.<br>- Paused: owner cannot delete; users cannot donate but may comment. The campaign can be resumed by its owner.<br>- Suspended: owner cannot delete; users cannot donate, comment, or view it. Only administrators can access, modify, or unsuspend the campaign. |

## A5 : Relational Schema

This artifact contains the Relational Schema obtained by the mapping from the Conceptual Data Model in agreement with the BCNF.

### 5.1 Relational Schema

| ID | Relation |
|----|----------|
| R01 | user_account(<ins>id</ins>, email UK NN, name NN, password NN, join_date NN DF Today, profile_picture) |
| R02 | campaign(<ins>id</ins>, name NN, description NN, goal NN, funded DF 0 NN CK funded \<= goal, start_date NN DF Today, close_date CK (close_date IS NULL OR close_date \>= start_date), end_date CK (end_date IS NULL OR (end_date \>= start_date AND (close_date IS NULL OR close_date \>= end_date))), state NN CK state IN States, creator_id -\> user.id, category_id NN -\> category.id) |
| R03 | admin(<ins>id</ins>, email UK NN, password NN) |
| R04 | oauth_account(<ins>id</ins>, provider, provider_email NN, provider_user_id NN, avatar_url, access_token, refresh_token, token_expires_at, user -\> user.id) |
| R05 | blocked_user(<ins>id</ins> -\> user.id, datetime NN, reason NN) |
| R06 | appeal(<ins>id</ins>, block -\> blocked_user.id, whining NN, datetime NN) |
| R07 | comment(<ins>id</ins>, content NN, datetime NN, author -\> user.id, campaign -\> campaign.id NN, parent -\> comment.id, notification -\> notification.id NN) |
| R08 | transaction(<ins>id</ins>, datetime NN, amount NN CK \> 0, is_valid NN DF TRUE, author -\> user.id, campaign -\> campaign.id NN, notification -\> notification.id NN) |
| R09 | category(<ins>id</ins>, name UK NN) |
| R10 | update(<ins>id</ins>, content NN, datetime NN DF Today, campaign -\> campaign.id NN, notification -\> notification.id) |
| R11 | resource(<ins>id</ins>, name NN, path NN, order NN, campaign -\> campaign.id, update -\> update.id NN) |
| R12 | notification(<ins>id</ins>, content NN, link NN, type NN, datetime NN DF Today) |
| R13 | owner(<ins>user</ins> -\> user.id, <ins>campaign</ins> -\> campaign.id NN) |
| R14 | follow(<ins>user</ins> -\> user.id NN, <ins>campaign</ins> -\> campaign.id NN) |
| R15 | user_notification(<ins>user</ins> -\> user.id NN, <ins>notification</ins> -\> notification.id NN, is_read NN DF FALSE, snooze_until) |

UK = Unique Key
NN = Not Null
CK = Check
DF = Default

### 5.2 Domains



| Domain Name | Domain Specification |
| ----------- | -------------------- |
| Today | DATE DEFAULT CURRENT_DATE |
| State |  ENUM (‘unfunded’, ‘ongoing’, ‘completed’, ‘paused’, ‘suspended’) |
| Type |  ENUM ('update', 'transaction', 'comment')|


### 5.3 Schema Validation

Ensures each table’s attributes are uniquely determined by its keys, validating data integrity, preventing redundancy, and confirming the schema follows BCNF normalization.


| TABLE R01 | user_account |
| ------------|-------------|
| Keys | {id}, {email} |
|Functional Dependencies: | |
| FD0101a | {id} → {email, name, password, join_date, profile_picture} |
|  FD0101b |{email} → {id, name, password, join_date, profile_picture} |

| TABLE R02 | campaign |
| ----------|--------------|
| Keys | {id} |
|Functional Dependencies: | |
| FD0102 | {id} → {name, description, funded, goal, start_date, close_date, end_date, state, creator, category} |

| TABLE R03 | admin |
| ----------|--------------|
| Keys | {id}, {email} |
|Functional Dependencies: | |
| FD0103a | {id} → {email, password} |
| FD0103b | {email} → {id, password} |
 
| TABLE R04 | oauth_account |
| ----------|--------------|
| Keys | {id}, {provider,provider_user_id} |
|Functional Dependencies: | |
| FD0104a | {id} → {provider, provider_email, provider_user_id, avatar_url, access_token, refresh_token, token_expires_at, user} |
| FD0104b | {provider,provider_user_id} → {id, provider_email, avatar_url, access_token, refresh_token, token_expires_at, user} |

| TABLE R05 | blocked_user|
|-----------|-------------|
| Keys      | {id} |
|Functional Dependencies: | |
| FD0105| {id} → {datetime, reason}|

| TABLE R06 | appeal|
|-----------|-------------|
| Keys      | {id}        |
|Functional Dependencies: | |
| FD0106 | {id} → {block, whining, datetime}|

| TABLE R07 | comment |
|-----------|-------------|
| Keys      | {id}, {notification}      |
|Functional Dependencies: | |
| FD0107a | {id} → {content, datetime, author, campaign, parent,notification}|
| FD0107b | {notification} → {content, datetime, author, campaign, parent, id}|


| TABLE R08 | transaction |
|-----------|-------------|
| Keys      | {id}, {notification}|
|Functional Dependencies: | |
| FD0108a | {id} → {datetime, amount, is_valid, author, campaign, notification}|
| FD0108b | {notification} → {datetime, amount, is_valid, author, campaign, id}|


| TABLE R09 | category |
| --------| -----------|
| Keys    | {id},{name} |
|Functional Dependencies: | |
| FD0109a | {id} → {name} |
| FD0109b | {name} → {id}|

| TABLE R10 | update |
| --------| -----------|
| Keys    | {id},{notification} |
|Functional Dependencies: | |
| FD0110a  |{id} → {content, datetime, campaign, notification}|
| FD0110b  |{notification} → {content, datetime, campaign, id}|


| TABLE R11 | resource |
| --------| -----------|
| Keys    | {id}, {location} |
|Functional Dependencies: | |
| FD0111a | {id} → {name, location, order, campaign, update}|
| FD0111b | {location} → {id,name, order, campaign, update}|

| TABLE R12 | notification |
| --------| -----------|
| Keys    | {id} |
|Functional Dependencies: | |
| FD0112 | {id} → {content, link, type, datetime}|

| TABLE R13 | owner |
| --------| -----------|
| Keys    | {user, campaign} |
|Functional Dependencies: | |
| FD0116 | {user, campaign} → ∅|

| TABLE R14 | follow |
| --------| -----------|
| Keys    | {user, campaign} |
|Functional Dependencies: | |
| FD0117 | {user, campaign} → ∅|


| TABLE 15 | user_notification |
| -------- | ----------------- |
| Keys    | {user, notification} |
| Functional Dependencies:| |
| FD0118 | {user, notification} -> {is_read, snooze_until} |

## A6 : Indexes, Integrity and Populated Database


### 1. Database workload

Understanding the system’s workload and performance goals is key to effective database design. This includes estimating the number of tuples in each relation and their expected growth over time. The table below summarizes these estimates for the database.

| ID  | Relation name               | Order of magnitude      | Estimated growth   |
|-----|-----------------------------|-------------------------|--------------------|
| R01 | user_account                | 10 k (tens of thousands)| 100(hundreds) /day |
| R02 | campaign                    | 1 k (thousands)         | 10(tens) /day      |
| R03 | admin                       | 10 (tens)               | ~0 /day            |
| R04 | oauth_account               | 10 k                    | 10 /day            |
| R05 | blocked_user                | 100 (hundreds)          | 1(unit) /day       |
| R06 | appeal                      | 100                     | 1 /day             |
| R07 | comment                     | 10 k                    | 100 /day           |
| R08 | transaction                 | 10 k                    | 100 /day           |
| R09 | category                    | 100                     | ~0 /day            |
| R10 | update                      | 1 k                     | 10 /day            |
| R11 | resource                    | 1 k                     | 10 /day            |
| R12 | notification                | 10 k                    | 100 /day           |
| R13 | owner                       | 1 k                     | 10 /day            |
| R14 | follow                      | 10 k                    | 100 /day           |
| R15 | user_notification           | 10 k                    | 100 /day           |



### 2 Proposed Indices

#### 2.1 Performance Indices


<table>
  <tr>
    <th>Index</th>
    <th>IDX01</th>
  </tr>
  <tr>
    <td>Relation</td>
    <td>campaign</td>
  </tr>
  <tr>
    <td>Attribute</td>
    <td>(state, start_date)</td>
  </tr>
  <tr>
    <td>Type</td>
    <td>B-Tree</td>
  </tr>
  <tr>
    <td>Cadinality</td>
    <td>Medium</td>
  </tr>
  <tr>
    <td>Clustering</td>
    <td>No</td>
  </tr>
  <tr>
    <td>Justification</td>
    <td>This index optimizes queries that filter campaigns by their state (e.g., ongoing, completed) and sort or search them based on the most recent start date. Since users frequently browse campaigns that are currently active and typically expect to see the newest ones first, indexing (state, start_date) reduces query execution time by allowing PostgreSQL to efficiently isolate campaigns in the desired state and retrieve them in the correct order without extra sorting.</td>
  </tr>
  <tr>
  <td colspan="2"><b>SQL Code</b></td>
  </tr>
    </tr>
  <tr>
  <td colspan="2"><pre><code>CREATE INDEX idx_campaign_state_start
    ON campaign (state, start_date DESC);</code></pre>
</td>
  </tr>
</table>


<table>
  <tr>
    <th>Index</th>
    <th>IDX02</th>
  </tr>
  <tr>
    <td>Relation</td>
    <td>comment</td>
  </tr>
  <tr>
    <td>Attribute</td>
    <td>(parent_id, created_at)</td>
  </tr>
  <tr>
    <td>Type</td>
    <td>B-Tree</td>
  </tr>
  <tr>
    <td>Cadinality</td>
    <td>Medium</td>
  </tr>
  <tr>
    <td>Clustering</td>
    <td>No</td>
  </tr>
  <tr>
    <td>Justification</td>
    <td>The comments have a defined structure similar to a Tree, by creating this index we eficiently are able to access all the comments children of a specific comment and display them by the order that they where created.</td>
  </tr>
  <tr>
  <td colspan="2"><b>SQL Code</b></td>
  </tr>
    </tr>
  <tr>
  <td colspan="2"><pre><code>CREATE INDEX idx_comment_parent_created
ON comment (parent_id, created_at);</code></pre>
</td>
  </tr>
</table>

<table>
  <tr>
    <th>Index</th>
    <th>IDX03</th>
  </tr>
  <tr>
    <td>Relation</td>
    <td>user_notification</td>
  </tr>
  <tr>
    <td>Attribute</td>
    <td>(user, snooze_until)</td>
  </tr>
  <tr>
    <td>Type</td>
    <td>B-Tree</td>
  </tr>
  <tr>
    <td>Cadinality</td>
    <td>High</td>
  </tr>
  <tr>
    <td>Clustering</td>
    <td>No</td>
  </tr>
  <tr>
    <td>Justification</td>
    <td>The table notification_user whould be a subject of many queries in order to keep the user updated on the current notifications, for that we use a index that filters per-user and ignores the already read ones so that the query fastly returns only meaningfull ones.</td>
  </tr>
  <tr>
  <td colspan="2"><b>SQL Code</b></td>
  </tr>
    </tr>
  <tr>
  <td colspan="2">
  <pre><code>  CREATE INDEX idx_user_notification_active
  ON user_notification (user, snooze_until)
  WHERE is_read = FALSE;</code></pre>
  </td>
  </tr>
</table>
