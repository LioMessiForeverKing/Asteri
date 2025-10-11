# 🌌 **Asteri MVP: System Design Overview**

Goal: Build an MVP that clusters 100 users into 10 groups of 10 based on **similarity in their YouTube and Pinterest data.**

## 🧩 **1. System Overview**

### Flow:

1. **User logs in with Google** → grants access to their **YouTube account.**
2. After YouTube connection, user **connects Pinterest** → grants access to their boards and pins.
3. The system retrieves data from both sources, converts it into embeddings, and groups similar users.
4. The backend forms **10 groups of 10**, representing shared aesthetic or interest clusters.

## 🧠 **2. Data Processing Architecture**

### a. **Input Data**

- **From YouTube:**
    - Channel subscriptions
    - Watch history or liked videos (if permitted)
    - Video titles, descriptions, categories
- **From Pinterest:**
    - Board names
    - Pin titles/descriptions
    - Image tags or categories
### b. **Embedding Layer**
Each user’s data (text + image content) is turned into numerical **vector embeddings** that represent their “interest signature.”

Use:
- **YouTube:** `text-embedding-3-large` for titles and descriptions
- **Pinterest:** `CLIP` or similar model for image embeddings

Then compute a single **user embedding** for each data source:

```python
youtube_vector = mean(embedding(video_1), ..., embedding(video_n))
pinterest_vector = mean(embedding(pin_1), ..., embedding(pin_m))
```

Combine both:

```python
final_vector = 0.6 * youtube_vector + 0.4 * pinterest_vector
```

---

### c. **Similarity Computation**

Compare every user’s final vector with every other user using **cosine similarity.**  
This gives you a **100x100 similarity matrix.**

```
Similarity[i][j] = cosine(user_vector_i, user_vector_j)
```

---

### d. **Clustering**

Use unsupervised clustering (e.g., **K-Means**) to automatically form 10 groups:

```python
from sklearn.cluster import KMeans

kmeans = KMeans(n_clusters=10, random_state=42)
labels = kmeans.fit_predict(user_vectors)
```

Each user gets assigned a `cluster_id` (0–9).

---

### e. **Output**

Each cluster represents a small community of users with highly similar creative or aesthetic preferences.  
These clusters become **chat groups or discovery circles** inside Asteri.
##  **3. Database Schema (Supabase/Postgres)**

|Table|Columns|Purpose|
|---|---|---|
|**users**|id, name, email, google_id, youtube_url, pinterest_url, created_at|user info|
|**user_embeddings**|user_id (FK), source (‘youtube’), vector (pgvector 3072), updated_at|store per-user vector|
|**clusters**|cluster_id, centroid_vector, created_at|store cluster centroids|
|**user_clusters**|user_id (FK), cluster_id (FK), similarity_score|store final user–cluster mapping|

---

##  **4. Embedding Pipeline (Supabase Edge Function)**

- Client collects YouTube texts (channel titles, liked video titles) and calls Supabase Edge Function `embed_youtube` with body `{ texts, model: 'text-embedding-3-large', source: 'youtube' }`.
- Edge function calls OpenAI embeddings, mean-pools the vectors, and upserts into `public.user_embeddings` for the authenticated user.
- Client shows the embedded item count.

##  **5. Matching Algorithm (Example)**

```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.cluster import KMeans

similarity_matrix = cosine_similarity(user_vectors)
kmeans = KMeans(n_clusters=10, random_state=42)
labels = kmeans.fit_predict(user_vectors)

assignments = {user_id: int(label) for user_id, label in zip(user_ids, labels)}
```

This determines who belongs together and stores it in the database.

## **5. MVP Architecture Stack**

|Layer|Tech|
|---|---|
|**Frontend**|Next.js (web) or Expo (mobile)|
|**Auth**|Google OAuth → YouTube API + Pinterest OAuth|
|**Backend**|FastAPI / Node.js for embeddings + clustering|
|**Database**|Supabase (Postgres)|
|**Realtime Chat**|Supabase Realtime / WebSockets|
|**Embeddings**|OpenAI + CLIP|
|**Storage**|Supabase or AWS S3 (for image caching)|
|**Compute**|AWS Lambda or local server for batch clustering|

##  **6. Example User Journey**

1. User signs in with Google → connects YouTube → connects Pinterest.
2. Backend fetches data from both → generates embeddings.
3. Clustering script runs → assigns users to 1 of 10 groups.
4. Groups appear inside the app → users can chat or explore their “Asteri cluster.”
5. Admin dashboard shows group stats and similarity patterns.