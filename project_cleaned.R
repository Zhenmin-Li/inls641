library(knitr)
library(dplyr)
library(stringr)
library(lubridate)
library(tm)
library(tidytext)

#Load the data

tweets <- timetk::tk_tbl(data.table::fread("tweets.v1.4.csv", encoding= "UTF-8"))


#date formatting and cleaning
tweets$date <- ymd(tweets$date)
tweets <- tweets %>% filter(date >= "2016-07-18" & date <= "2022-10-18")#I leave a filter here for future use
glimpse(tweets)


#text mining section


#print("clean the line end, amp, url and icon")
tweets$text <- str_replace_all(tweets$text, "[\n]" , "") 
tweets$text <- str_replace_all(tweets$text, "&amp", "") 
tweets$text <- str_replace_all(tweets$text, "http.*" , "")
tweets$text <- iconv(tweets$text, "latin1", "ASCII", sub="")

#build the corpus
#vcorpus strictly requires the column name to be coordinate, so change 2 name
id <- rownames(tweets)
tweets <- cbind(doc_id=id, tweets)

Corpus <- DataframeSource(tweets)
Corpus <- VCorpus(Corpus)
meta(Corpus)


#clean the corpus
#upper2lower, remove num, stopwords, punc, and strip
CleanCorpus <- function(x){
  x <- tm_map(x, content_transformer(tolower))
  x <- tm_map(x, removeNumbers) #remove numbers before removing words. 
  x <- tm_map(x, removeWords, tidytext::stop_words$word)
  x <- tm_map(x, removePunctuation)
  x <- tm_map(x, stripWhitespace)
  return(x)
}


#remove some high frequency words
RemoveNames <- function(x) {
  x <- tm_map(x, removeWords, c("covid", "pandemic", "coronavirus","trump"))
  return(x)
}

CreateTermsMatrix <- function(x) {
  x <- TermDocumentMatrix(x)
  x <- as.matrix(x)
  y <- rowSums(x)
  y <- sort(y, decreasing=TRUE)
  return(y)
}

#conduct the cleaning
#not remove the name
Corpus <- CleanCorpus(Corpus)
TermFreq <- CreateTermsMatrix(Corpus)


#show the content
content(Corpus[[1]])


#create directory for figures

Corpus1 <- RemoveNames(Corpus)
TermFreq1 <- CreateTermsMatrix(Corpus1)

#tidytext
#we need to break the corpus list to show bigramms
Tidy <- tidy(Corpus)
Tidy1 <- tidy(Corpus1) #without names


#sentiment analysis

DocMeta <- meta(Corpus1)
DocMeta$date <- date(DocMeta$date)
Tidy1$date <- DocMeta$date
Tidy1$location <- DocMeta$location

Words <- Tidy1 %>% unnest_tokens(word, text)

get_sentiments("afinn")
Afinn <- Words %>% inner_join(get_sentiments("afinn"), by="word")
sentiment <- Afinn[, c("date", "location", "word", "value")]
write.csv(sentiment,'sentiment_afinn.csv',row.names=FALSE)
