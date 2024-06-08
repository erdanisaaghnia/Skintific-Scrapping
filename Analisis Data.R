library(tm)
library(SnowballC)
library(wordcloud)
library(tidytext)
library(tidyverse)
library(RColorBrewer)
library(mongolite)
library(stringr)
library(ggplot2)
library(textdata)
library(textclean)
library(SentimentAnalysis)
library(dplyr)
library(reshape2)

#===============ambil data from mongoDB=============================#
# Define your collection and database
collection <- "TaskWeb"
db <- "Task-Web-Scrapping"

# Include the authentication database in the URL
url <- "mongodb+srv://erdanisaaghnia:Tigabelas13@cluster0.5gc6whg.mongodb.net/"

# Connect to the MongoDB database and collection
conn <- mongo(collection = collection, db = db, url = url)

all_reviews<-conn$find('{}')
head(all_reviews)

#========================VISUALISASI=============================================#

# Menghitung frekuensi setiap shade cushion
shade_freq <- all_reviews %>%
  count(shade_cushion)

# Membuat bar chart dengan label jumlah review
ggplot(shade_freq, aes(x = shade_cushion, y = n)) +
  geom_bar(stat = "identity", fill = "beige") +
  geom_text(aes(label = n), vjust = -0.5) +
  labs(x = "Shade Cushion", y = "Jumlah Review") +
  theme_minimal()


# Menghitung frekuensi tempat pembelian
purchase_freq <- all_reviews %>%
  count(purchase_place, sort = TRUE) %>%
  top_n(5)

# Membuat bar chart dengan 5 tempat pembelian terbanyak dengan warna pastel
ggplot(purchase_freq, aes(x = reorder(purchase_place, n), y = n, fill = purchase_place)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = n), vjust = -0.5) +
  labs(x = "Tempat Pembelian", y = "Jumlah Review") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
  scale_fill_brewer(palette = "Pastel1")

# Menghitung frekuensi setiap lama penggunaan
period_freq <- all_reviews %>%
  count(usage_period)  

# Membuat bar chart dengan label jumlah review
ggplot(period_freq, aes(x = usage_period, y = n)) +
  geom_bar(stat = "identity", fill = "lightcoral") +
  geom_text(aes(label = n), vjust = -0.5) +
  labs(x = "Periode Penggunaan", y = "Jumlah Review") +
  theme_minimal()

#========================ANALISIS SENTIMEN========================================#
data_review <- all_reviews$review
data_review


# Stop words yang diberikan
indonesian_stop_words <- data.frame(
  word = c("aku", "ini", "dan", "di", "yang",
           "untuk", "dengan", "ke", "dari", "saat",
           "bisa", "juga", "sudah", "ada", "itu", "akan",
           "karena", "apa", "saya", "kamu","banget","nya","pake","ga","tapi",
           "yg","buat","jadi","sih","bgt","aja","dia","sama","udah",
           "kalo","gak","to","agak","bikin","lagi","jam","cushion","ku","ya","mau","tuh","pun",
           "tetep","jd","pun","tp","nga","cuma","deh")
)

# Menggabungkan stop words bahasa Indonesia dengan stop words bahasa Inggris dari library tm
all_stop_words <- stopwords("en") %>%
  c(indonesian_stop_words$word) %>%
  unique() %>%
  data.frame(word = .)

# Fungsi untuk menghilangkan emoji
remove_emoji <- function(text) {
  gsub("[\\p{So}\\p{Cn}]", "", text, perl = TRUE)
}

# Fungsi untuk mengubah kata dengan karakter berulang
normalize_text <- function(text) {
  gsub('(.)\\1+', '\\1', text)
}

# Tokenisasi dan preprocessing
review_words <- data.frame(review = data_review) %>%
  mutate(review = map_chr(review, remove_emoji)) %>%
  mutate(review = map_chr(review, normalize_text)) %>%
  unnest_tokens(word, review) %>%
  anti_join(all_stop_words, by = "word")

# Menampilkan hasil tokenisasi dan stop words removal
print(review_words)

# Mengambil lexicon bing dari tidytext
bing_sentiments <- get_sentiments("bing")

# Tambahkan kata-kata sentimen dalam bahasa Indonesia secara manual (contoh beberapa kata)
indonesian_sentiments <- data.frame(
  word = c("bagus", "suka", "mahal", "oke", "mengecewakan", "terbaik", "buruk", "murah", "cantik", "jelek", "mewah", "flawless", "cerah", "kusem", "demak","cocok",
           "cinta","oksidasi"),
  sentiment = c("positive", "positive", "negative", "positive", "negative", "positive", "negative", "positive", "positive", "negative", "positive", "positive", "positive", "negative", "negative","positive",
                "positive","negative")
)

# Menggabungkan lexicon bahasa Inggris dan Indonesia
combined_sentiments <- bind_rows(bing_sentiments, indonesian_sentiments)

# Melakukan analisis sentimen
sentiment_analysis <- review_words %>%
  inner_join(combined_sentiments, by = "word")

# Menampilkan hasil analisis sentimen
print(sentiment_analysis)


# Membuat word cloud
review_words %>%
  count(word, sort = TRUE) %>%
  with(wordcloud(word, n, max.words = 200))

# Menghitung jumlah kata positif dan negatif
sentiment_counts <- sentiment_analysis %>%
  count(sentiment)

# Menampilkan hasil perhitungan sentimen
print(sentiment_counts)

# Visualisasi sentimen positif dan negatif
sentiment_analysis %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("#9ACD32", "#FF6347"),
                   max.words = 200)

# Menghitung kata-kata positif dan negatif
sentiment_counts <- sentiment_analysis %>%
  count(sentiment, word, sort = TRUE)

# Filter kata-kata positif dan negatif
positive_words <- sentiment_counts %>%
  filter(sentiment == "positive") %>%
  top_n(10) %>%
  arrange(desc(n))

negative_words <- sentiment_counts %>%
  filter(sentiment == "negative") %>%
  top_n(10) %>%
  arrange(desc(n))

# Menampilkan kata-kata positif
print("Kata-kata Positif:")
print(positive_words)

# Menampilkan kata-kata negatif
print("Kata-kata Negatif:")
print(negative_words)

# Menyiapkan data untuk barplot
barplot_data <- sentiment_counts %>%
  filter(word %in% c(positive_words$word, negative_words$word)) %>%
  arrange(desc(n))

# Visualisasi barplot dengan warna pastel
ggplot(barplot_data, aes(x = reorder(word, n), y = n, fill = sentiment)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c("positive" = "#9ACD32", "negative" = "#FF6347")) +
  theme_minimal() +
  labs(x = "Kata-kata", y = "Jumlah", fill = "Sentimen") +
  theme(axis.text.y = element_text(size=10))
