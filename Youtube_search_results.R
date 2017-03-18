# First, you need to download PhantomJS headless WebKit from here http://phantomjs.org/download.html
# and extract it to a desired folder
install.packages("RSelenium")
library(RSelenium)
# installing and running the RSelenium package which we will use for driving
# the PhantomJS WebKit
psPath <-
  "C:/*/phantomjs-2.1.1-windows/bin/phantomjs.exe"
# provide the full path to phantomjs.exe on your harddrive
pJS <- phantom(pjs_cmd = psPath)
remDr <- remoteDriver(browserName = "phantomjs")
remDr$open()
# start phantomjs driver
URLs <-
  read.csv("C:/*/InitialURLsYt.csv",
           header = F)$V1
# Here you provide the path to csv file wiht URLs to search queries results
# with all filters you want (may be copied from YouTube interface once and 
# then just populated on all keywords).
# Here a sample InitialURLsYt.csv provided
URLs <- as.character(URLs)
# Stating that URLs varible has string (character) values
datalist1 = list()
datalist2 = list()
# Creating two lists: in datalist1 we will collect URLs to videos with 
# a particular keyword; in datalist2 we will collect all resulting lists
# of type datalist1. Afterwads we will combine them into one dataframe.
n=length(URLs)
library(tcltk)
pb <-
  tkProgressBar(
    title = "Collecting URLs",
    min = 0,
    max = n,
    width = 200
  )
for (i in 1:n) {
  # Creating a loop which goes through all keywords
  tryCatch({
    Sys.sleep(0.001)
    setTkProgressBar(pb, i, label = paste(round(i / n * 100, 1), "% done"))
    # This is only for visual control of the process. We create a progress bar
    # which shows the percentage of keywords searches processed.
    remDr$navigate(URLs[i])
    # Go to the i-th URL in a loop
    for (k in 1:100) {
      # Here we state how many pages of results we should try to handle. We should specify
      # the maximum we have. I.e. if for one keyword 20 pages available, and for the second
      # 50 pages available, then we should write "k in 1:49" as the first page doesn't count
      # (we're already on in when we call remDr$navigate(URLs[i]))
      URLRaw <-
        remDr$findElements(
          using = 'css',
          "a.yt-uix-tile-link.yt-ui-ellipsis.yt-ui-ellipsis-2.yt-uix-sessionlink.spf-link"
        )
      # Here we specify a css-selector of an URL on a search results page. It is a selector
      # of a video title too. To find a unique css selector I recommend to use http://selectorgadget.com/
      Attr <- function(x)
      {
        x$getElementAttribute("href")
      }
      URL <- mapply(Attr, URLRaw)
      # Now we create a function which find a link attribute of each title and apply it to
      # all video titles on a page.
      data <- data.frame(rbind.fill(URL))
      colnames(data) <- c("URL")
      # We create a dataframe with all URLs from a page.
      datalist1[[k]] <- data
      # and put it to a dataframe list.
      remDr$findElement(using = 'css',
                        ".yt-uix-button-size-default:nth-child(8) .yt-uix-button-content")$clickElement()
      # After collecting the URLs we go to the next page by clicking the selector of the "Next" button.
      Sys.sleep(1)
    }
  }, error = function(e) {
  })
  datalist2[[i]] = do.call(rbind, datalist1)
  # We combine all URLs dataframes for a particular keyword and put it to a list 
  # of dataframes called datalist2
}
big_data = do.call(rbind, datalist2)
# Combining all dataframes with all URLs into a list
nrow(big_data)
# Optional. Just to see how many URLs we collect
big_data_ready <-
  as.data.frame(
    big_data,
    row.names = NULL,
    optional = FALSE,
    cut.names = FALSE,
    col.names = names(c("URL")),
    fix.empty.names = TRUE,
    stringsAsFactors = default.stringsAsFactors()
  )
# Transforming a resulting list into a dataframe.
write.csv2(
  big_data_ready,
  "C:/*/ResultURLYt.csv",
  col.names = TRUE,
  sep = ";"
)
# Saving the resulting dataframe to a csv file. Here you should provide the full path
# to a saving directory. Alternatively use file.choose() instean of path 
remDr$close()
# Close PhantomJS.