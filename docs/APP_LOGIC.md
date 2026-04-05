# App Logic

## Application Logic

### Users
- A user can create and/or be a member of up to **3 groups**. The same user cannot be in the **same group more than once**.
- Within each group, the user can choose the **top scorer**, the **champion**, and submit different **predictions**.
- A user may also exist **without a group** and, in that case, chooses the **top scorer**, the **champion**, and submits **predictions once**.
- A user **cannot** be both **without a group** and **in a group** at the same time.
- A username can be changed **before the tournament starts**.
- An account can be deleted only if the user is **not in any group** and only **before the tournament starts**.
- The group creator is the **captain** and can mark which members are **inactive**.

### Groups
- A group can contain up to **10 users**.
- Group predictions for a match, as well as prediction statistics, can be viewed **only after the match starts** and **only by that group**.
- The **global leaderboard** is visible to everyone.
- **AI summaries** will be available only for groups with **3 or more users**.
- AI summaries will cover **only that day’s matches**. On days with no matches, there will be **no summary**.
- The AI summary is **group-only**, and only **group members** can view it.
- If a user does not enter a prediction by kickoff, an **automatic prediction** will be filled in based on the **least-selected W/D/L outcome** in the prediction statistics, and the exact score will be **randomly generated**.
- The **top scorer** and **champion** can be selected until the **start of the tournament**; otherwise, they will be **auto-filled according to the least-selected percentage**.
- Predictions can be changed and edited **until kickoff**, and the **champion** and **top scorer** can be changed **until the tournament starts**.
- There may be **multiple top scorers**.

### Scoring
- Correct **W/D/L** prediction: **1 point**
- Exact score prediction: **3 points**
- Correct top scorer: **10 points**
- Correct champion: **10 points**
- Scoring is based on the **90-minute result**.
- Goals are counted **throughout the entire match**.
- In knockout-stage statistics, the app should display the **90-minute result**, **extra time**, and **penalties**.

### Data Sources
- National team names and top-scorer player names come from **API FOOTBALL**.

## Dashboard
- The clock displays the **time until the next match** and the **next match itself**. Once a match starts, it updates to show the **time until the following match** and that **next match**.
- Dashboard statistics display:
  - **Exact score prediction accuracy %**
  - **W/D/L prediction accuracy %**
  - **Positive W/D/L streak**
  - **Negative W/D/L streak**
- The **Groups** section shows the **next match** and **only the user’s own prediction**. After the match starts, it shows the **group’s predictions** and **prediction statistics**. After the match ends, it shows the **next match**.
- In the **Predictions** area, the app displays the match result for **90 minutes**, **extra time**, and **penalties**.
- Odds are checked starting **3 days before each match**.
- Match times and fixtures are checked **every day**.

## Data Pull Logic
- Data is pulled **120 minutes after kickoff**, and then **every 5 minutes if the match has not ended**.
- If there is **extra time**, data is pulled again **after 40 minutes**, and then **every 5 minutes** afterward.
