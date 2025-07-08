library(text2vec)
library(Matrix)
library(proxy)
library(stopwords)
library(DBI)
library(RSQLite)

# Function to get mentor data from the database (enhanced with demographics)
get_mentor_data <- function(con) {
  # Try enhanced table first, fallback to basic
  tryCatch({
    mentors_enhanced <- dbGetQuery(con, "SELECT * FROM mentors_enhanced")
    if (nrow(mentors_enhanced) > 0) {
      # Map enhanced data to mentor_profiles format for compatibility
      mentors_mapped <- data.frame(
        id = mentors_enhanced$id,
        name = mentors_enhanced$name,
        title = mentors_enhanced$title,
        expertise = mentors_enhanced$expertise_areas,
        bio = mentors_enhanced$bio,
        email = mentors_enhanced$email,
        image = "https://via.placeholder.com/100x100?text=M",
        # Additional demographic fields for enhanced matching
        age_range = mentors_enhanced$age_range,
        gender = mentors_enhanced$gender,
        ethnicity = mentors_enhanced$ethnicity,
        location = mentors_enhanced$location,
        industry = mentors_enhanced$industry,
        experience_years = mentors_enhanced$experience_years,
        stringsAsFactors = FALSE
      )
      return(mentors_mapped)
    }
  }, error = function(e) {
    message("Enhanced mentors table not found, using basic mentor_profiles")
  })
  
  # Fallback to basic mentor_profiles
  dbGetQuery(con, "SELECT * FROM mentor_profiles")
}

# Create mentor embeddings from DB (enhanced with demographics)
default_embedding_system <- function(con) {
  mentor_data <- get_mentor_data(con)
  
  # Enhanced text creation including demographic and professional data
  mentor_texts <- paste(
    mentor_data$name,
    mentor_data$title,
    mentor_data$expertise,
    mentor_data$bio,
    # Include demographic and professional context for better matching
    ifelse(is.null(mentor_data$location), "", mentor_data$location),
    ifelse(is.null(mentor_data$industry), "", mentor_data$industry),
    ifelse(is.null(mentor_data$experience_years), "", mentor_data$experience_years),
    ifelse(is.null(mentor_data$age_range), "", mentor_data$age_range)
  )
  tokens <- word_tokenizer(tolower(mentor_texts))
  it_train <- itoken(tokens, progressbar = FALSE)
  vocab <- create_vocabulary(it_train, stopwords = stopwords("en"))
  vocab <- prune_vocabulary(vocab, term_count_min = 1, doc_count_min = 1)
  vectorizer <- vocab_vectorizer(vocab)
  dtm_train <- create_dtm(it_train, vectorizer)
  tfidf <- TfIdf$new(norm = "l2", sublinear_tf = TRUE)
  dtm_tfidf <- fit_transform(dtm_train, tfidf)
  
  # Robust LSA: Only use if enough mentors/features and matrix is not singular
  if (ncol(dtm_tfidf) > 2 && nrow(dtm_tfidf) > 2) {
    lsa <- tryCatch({
      LSA$new(n_topics = min(30, nrow(dtm_tfidf) - 1))
    }, error = function(e) NULL)
    if (!is.null(lsa)) {
      dtm_final <- tryCatch({
        dtm_lsa <- fit_transform(dtm_tfidf, lsa)
        dtm_lsa
      }, error = function(e) dtm_tfidf)
    } else {
      dtm_final <- dtm_tfidf
      lsa <- NULL
    }
  } else {
    lsa <- NULL
    dtm_final <- dtm_tfidf
  }
  
  list(
    embeddings = dtm_final,
    vectorizer = vectorizer,
    tfidf = tfidf,
    lsa = lsa,
    mentor_data = mentor_data
  )
}

# Recommender function
get_mentor_recommendations <- function(student_answers, embedding_system, top_k = 3) {
  student_text <- tolower(paste(unlist(student_answers), collapse = " "))
  query_tokens <- word_tokenizer(student_text)
  it_query <- itoken(query_tokens, progressbar = FALSE)
  dtm_query <- create_dtm(it_query, embedding_system$vectorizer)
  dtm_query_tfidf <- transform(dtm_query, embedding_system$tfidf)
  
  # Only transform with LSA if it was successfully created and fitted
  if (!is.null(embedding_system$lsa)) {
    query_final <- tryCatch({
      transform(dtm_query_tfidf, embedding_system$lsa)
    }, error = function(e) {
      # If LSA transform fails, use TF-IDF directly
      dtm_query_tfidf
    })
  } else {
    query_final <- dtm_query_tfidf
  }
  
  similarities <- proxy::simil(query_final, embedding_system$embeddings, method = "cosine")
  similarities_vec <- as.numeric(similarities[1, ])
  top_indices <- order(similarities_vec, decreasing = TRUE)[1:min(top_k, length(similarities_vec))]
  result_df <- embedding_system$mentor_data[top_indices, ]
  match_scores <- similarities_vec[top_indices]
  
  recommendations <- list()
  for (i in seq_along(top_indices)) {
    recommendations[[i]] <- list(
      id = result_df$id[i],
      name = result_df$name[i],
      title = result_df$title[i],
      expertise = result_df$expertise[i],
      bio = result_df$bio[i],
      email = result_df$email[i],
      image = result_df$image[i],
      score = round(match_scores[i], 3)
    )
  }
  return(recommendations)
} 