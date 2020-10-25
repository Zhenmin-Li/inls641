#Some defection


library(webshot)
library(htmlwidgets)
library(knitr)
library(tidyr)
library(dplyr)
library(readr)
library(ggplot2)
library(tibble)
library(stringr)
library(gridExtra)
library(scales)
library(lubridate)
library(ggrepel)
library(reshape2)
library(kableExtra)
library(tm)
library(wordcloud)
library(wordcloud2)
library(tidytext)
library(textdata)
library(broom)
library(bit64)

#webshot::install_phantomjs()
#Load the data
#setwd("C:\\Users\\lzm11\\OneDrive\\course\\bios611\\bios611_course_project")

tweets <- timetk::tk_tbl(data.table::fread("tweets.v1.4.csv", encoding= "UTF-8"))


#date formatting and cleaning
#I only need tweets from  07.18 to 10.17 in 2016 data
tweets$date <- ymd(tweets$date)
tweets <- tweets %>% filter(date >= "2016-07-18" & date <= "2022-10-18")#I leave a filter here for future use
glimpse(tweets)


#text mining section


kable(head(tweets %>% select(text), 20), format = "html") %>%
  kable_styling() %>%
  column_spec(1, width = "19cm")


print("clean the line end, amp, url and icon")
tweets$text <- str_replace_all(tweets$text, "[\n]" , "") 
tweets$text <- str_replace_all(tweets$text, "&amp", "") 
tweets$text <- str_replace_all(tweets$text, "http.*" , "")
tweets$text <- iconv(tweets$text, "latin1", "ASCII", sub="")

#df <- tweets %>% mutate(male = grepl("church", text))

#build the corpus
#vcorpus strictly requires the column name to be coordinate, so change 2 name
id <- rownames(tweets)
tweets <- cbind(doc_id=id, tweets)

Corpus <- DataframeSource(tweets)
Corpus <- VCorpus(Corpus)

#inspect the corpus
content(Corpus[[1]])

#clean the corpus
#upper2lower, remove num, stopwords, punc, and strip
CleanCorpus <- function(x){
  x <- tm_map(x, content_transformer(tolower))
  x <- tm_map(x, removeNumbers) #remove numbers before removing words. Otherwise "trump2016" leaves "trump"
  x <- tm_map(x, removeWords, tidytext::stop_words$word)
  x <- tm_map(x, removePunctuation)
  x <- tm_map(x, stripWhitespace)
  return(x)
}


#remove some high frequency words
#trump itself is a positive word acoording to sentiment corpus
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
dir.create("./figures/",showWarnings=FALSE);

#top 20 words histogram
DF_top20 <- data.frame(word=names(TermFreq), count=TermFreq)

t1 <- DF_top20[1:20,] %>%
  ggplot(aes(x=(reorder(word, count)), y=count)) +
  ggtitle("Word Frequency") +
  geom_bar(stat='identity', fill="red") + coord_flip() + theme(legend.position = "none") +
  labs(x="")

t1
#ggsave("./figures/top20.png", g)

#word cloud remove name
set.seed(1234)

Corpus1 <- RemoveNames(Corpus)
TermFreq <- CreateTermsMatrix(Corpus1)
DF_cloud <- data.frame(word=names(TermFreq), count=TermFreq)


wordcloud2::wordcloud2(DF_cloud[1:100,], color = "random-light", backgroundColor = "white", shuffle=FALSE, size=0.4)
#withr::with_dir('figures', saveWidget(w1, file="wordcloud1.html",selfcontained=FALSE))
#webshot("./figures/wordcloud1.html","./figures/wordcloud1.png", delay =5, vwidth = 480, vheight=480)

#tidytext
#we need to break the corpus list to show bigramms
Tidy <- tidy(Corpus)
Tidy1 <- tidy(Corpus1) #without names



#bigramms
plotBigrams <- function(tibble, topN=20, title="", color="#FF1493"){
  x <- tibble %>% select(text) %>%
    unnest_tokens(bigram, text, token = "ngrams", n = 2)
  y <- x %>% count(bigram, sort = TRUE) %>% top_n(topN, wt=n) %>%
    ggplot(aes(x=reorder(bigram, n), y=n)) +
    geom_bar(stat='identity', fill=color) + coord_flip() +
    theme(legend.position="none") + labs(x="", title=title)
}

b1 <- plotBigrams(Tidy, title="With covid", color="red")
b2 <- plotBigrams(Tidy1, title="Without covid", color="red")




grid.arrange(b1, b2, ncol=2)
#ggsave("./figures/bigramms.png", g, width = 800/72, height = 600/72, dpi = 150)

#sentiment analysis
get_sentiments("bing")

DocMeta <- meta(Corpus1)
DocMeta$date <- date(DocMeta$date)
Tidy1$date <- DocMeta$date

Words <- Tidy1 %>% unnest_tokens(word, text)
Bing <- Words %>% inner_join(get_sentiments("bing"), by="word")

b1 <- Bing %>% count(word, sentiment, sort=TRUE) %>%
  group_by(sentiment) %>% arrange(desc(n)) %>% slice(1:20) %>%
  ggplot(aes(x=reorder(word, n), y=n)) +
  geom_col(aes(fill=sentiment), show.legend=FALSE) +
  coord_flip() +
  facet_wrap(~sentiment, scales="free_y") +
  labs(x="", y="number of times used", title="most used words") +
  scale_fill_manual(values = c("positive"="green", "negative"="red"))


b1

#ggsave("./figures/mostused.png", g, width = 800/72, height = 600/72, dpi = 150)

#time series
t1 <- Bing %>% group_by(date) %>% count(sentiment) %>%
  spread(sentiment, n) %>% mutate(score=positive-negative) %>%
  ggplot(aes(x=date, y=score)) +
  scale_x_date(limits=c(as.Date("2020-02-01"), as.Date("2020-10-20")), date_breaks = "1 month", date_labels = "%b") +
  geom_line(stat="identity", col="blue") + geom_smooth(col="red") + labs(title="Sentiment")

t1
#ggsave("./figures/time_bing.png", g, width = 800/72, height = 600/72, dpi = 150)

#sentiment analysis afinn
get_sentiments("afinn")

Afinn <- Words %>% inner_join(get_sentiments("afinn"), by="word")

a1 <- Afinn %>%  group_by(date) %>% summarise(value=sum(value)) %>%
  ggplot(aes(x=date, y=value)) +
  scale_x_date(limits=c(as.Date("2020-02-01"), as.Date("2020-10-20")), date_breaks = "1 month", date_labels = "%b") +
  geom_line(stat="identity", col="blue") + geom_smooth(col="red") + labs(title="Sentiment")

a1
#ggsave("./figures/time_affin.png", g, width = 800/72, height = 600/72, dpi = 150)

#sentiment nrc
get_sentiments("nrc")

Nrc <- Words %>% inner_join(get_sentiments("nrc"), by="word")

n1 <- Nrc %>% filter(date <= "2017-02-04") %>% count(sentiment) %>%
  ggplot(aes(x=sentiment, y=n, fill=sentiment)) +
  geom_bar(stat="identity") + coord_polar() +
  theme(legend.position = "none", axis.text.x = element_blank()) +
  geom_text(aes(label=sentiment, y=500)) +
  labs(x="", y="", title="2016")
n2 <- Nrc %>% filter(date > "2017-02-04") %>% count(sentiment) %>%
  ggplot(aes(x=sentiment, y=n, fill=sentiment)) +
  geom_bar(stat="identity") + coord_polar() +
  theme(legend.position = "none", axis.text.x = element_blank()) +
  geom_text(aes(label=sentiment, y=500)) +
  labs(x="", y="", title="2020")
g <- grid.arrange(n1, n2, nrow=1)
ggsave("./figures/nrc.png", g, width = 800/72, height = 600/72, dpi = 150)


