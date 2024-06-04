# Memuat pustaka yang diperlukan
library(rvest)
library(purrr)
library(dplyr)

message('Scraping Data')
# Fungsi untuk scraping data dari satu halaman
scrape_page <- function(url, page_number, shade_cushion) {
  page_url <- paste0(url, "?page=", page_number)
  
  tryCatch({
    page <- read_html(page_url)
    
    review <- page %>%
      html_nodes(".text-content") %>%
      html_text()
    
    user <- page %>%
      html_nodes(".card-profile-wrapper .text-wrapper .profile-username a") %>%
      html_text()
    
    purchase_info <- page %>%
      html_nodes(".information-wrapper b") %>%
      html_text() %>%
      trimws()
    
    usage_period <- purchase_info[seq(1, length(purchase_info), 2)]
    purchase_place <- purchase_info[seq(2, length(purchase_info), 2)]
    
    length_diff <- max(length(user), length(review), length(usage_period), length(purchase_place))
    if(length(user) < length_diff) user <- c(user, rep(NA, length_diff - length(user)))
    if(length(review) < length_diff) review <- c(review, rep(NA, length_diff - length(review)))
    if(length(usage_period) < length_diff) usage_period <- c(usage_period, rep(NA, length_diff - length(usage_period)))
    if(length(purchase_place) < length_diff) purchase_place <- c(purchase_place, rep(NA, length_diff - length(purchase_place)))
    
    data.frame(user = user, review = review, usage_period = usage_period, purchase_place = purchase_place, shade_cushion = shade_cushion, stringsAsFactors = FALSE)
  }, error = function(e) {
    message(paste("Error on page:", page_number))
    return(data.frame(user = NA, review = NA, usage_period = NA, purchase_place = NA, shade_cushion = shade_cushion, stringsAsFactors = FALSE))
  })
}

# Scraping data untuk masing-masing produk

# Produk 1: Cushion 02 Ivory, 27 halaman
all_reviews_product1 <- map_df(1:27, function(page_number) {
  scrape_page("https://reviews.femaledaily.com/products/face/bb-cream/skintific/cover-all-perfect-cushion-02-ivory", page_number, "Cushion 02 Ivory")
})

# Produk 2: Cushion 03 Petal, 9 halaman
all_reviews_product2 <- map_df(1:9, function(page_number) {
  scrape_page("https://reviews.femaledaily.com/products/foundation/liquid/skintific/cover-all-perfect-cushion-03-petal", page_number, "Cushion 03 Petal")
})

# Produk 3: Cushion 01 Vanilla, 8 halaman
all_reviews_product3 <- map_df(1:8, function(page_number) {
  scrape_page("https://reviews.femaledaily.com/products/foundation/liquid/skintific/cover-all-perfect-cushion-01-vanilla", page_number, "Cushion 01 Vanilla")
})

# Produk 4: Cushion 03a Almond, 6 halaman
all_reviews_product4 <- map_df(1:6, function(page_number) {
  scrape_page("https://reviews.femaledaily.com/products/foundation/liquid/skintific/cover-all-perfect-cushion-03a-almond", page_number, "Cushion 03a Almond")
})

# Produk 5: Cushion 04 Beige, 5 halaman
all_reviews_product5 <- map_df(1:5, function(page_number) {
  scrape_page("https://reviews.femaledaily.com/products/foundation/liquid/skintific/cover-all-perfect-cushion-04-beige", page_number, "Cushion 04 Beige")
})

# Produk 6: Cushion 05 Sand, 2 halaman
all_reviews_product6 <- map_df(1:2, function(page_number) {
  scrape_page("https://reviews.femaledaily.com/products/foundation/liquid/skintific/cover-all-perfect-cushion-05-sand", page_number, "Cushion 05 Sand")
})

# Menggabungkan semua data frame menjadi satu
all_reviews <- bind_rows(all_reviews_product1, all_reviews_product2, all_reviews_product3, all_reviews_product4, all_reviews_product5, all_reviews_product6)

#Sample
data_scrape <- all_reviews[sample(nrow(all_reviews), 20), ]

# MONGODB
message('Input Data to MongoDB Atlas')
library(mongolite)

# Define your collection and database
collection <- "TaskWeb"
db <- "Task-Web-Scrapping"

# Include the authentication database in the URL
url <- "mongodb+srv://erdanisaaghnia:Tigabelas13@cluster0.5gc6whg.mongodb.net/"

# Connect to the MongoDB database and collection
conn <- mongo(collection = collection, db = db, url = url)

conn$insert(data_scrape)
rm(conn)

