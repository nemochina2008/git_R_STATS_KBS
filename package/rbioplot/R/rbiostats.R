#' @title rbiostats
#'
#' @description A simple to use function for comprehensive statistical analyses.
#' @param fileName Input file name. Case sensitive and be sure to type with quotation marks. Currently only takes \code{.csv} files.
#' @param Tp Type of the intended statistical test. e sure to type with quotation marks. Options are: "t-test", "Tukey" and "Dunnett" (Case insensitive). Default is "ANOVA".
#' @return Outputs a \code{.txt} file with Shapiro-Wilk normality test results and the results of the statistical analysis of interest.
#' @importFrom multcomp glht mcp
#' @examples
#' \dontrun{
#' rbiostats("data.csv","Tukey")
#' rbiostats("data2.csv","t-test")
#' }
#' @export
rbiostats <- function(fileName, Tp = "ANOVA"){
  rawData <- read.csv(file = fileName, header = TRUE, na.strings = "NA", stringsAsFactors = FALSE, check.names = FALSE)
  rawData[[1]] <- factor(rawData[[1]], levels = c(unique(rawData[[1]]))) # avoid R's automatic re-ordering the factors automatically - it will keep the "type-in" order

  cNm <- colnames(rawData)

  # below: nchar() counts the number of the characters: note the diference between length(),
  # which counts "how many" the *whole* character strings.
  # ALSO, to use substr(), the object has to have "no quote" - use the function noquote() to achieve.
  cat(paste(tolower(Tp), " test results written to file: ", substr(noquote(fileName), 1, nchar(fileName) - 4), ".stats.txt ...", sep = "")) # initial message

  sink(file = paste(substr(noquote(fileName), 1, nchar(fileName) - 4), ".stats.txt", sep = ""), append = FALSE)
  # below: Shapiro-Wilk normality test. p>0.5 means the data is normal.
  print(sapply(cNm[-1],
               function(i)tapply(rawData[[i]], rawData[1], function(x)shapiro.test(x)),
               simplify = FALSE))
  # below: stats
  print(sapply(cNm[-1], function(x){
    quoteName <- paste0("`", x, "`", sep = "")
    fml <- paste(quoteName, cNm[1], sep = "~")
    Mdl <- aov(formula(fml), data = rawData) # fit an analysis of variance model by a call to lm(), applicable for both balanced or unbalanced data set.
    # below: make sure to chain if else in this way!
    if (tolower(Tp) %in% c("t-test", "t test", "ttest", "t")){
      if (nlevels(rawData[[1]]) == 2){
        Control <- subset(rawData[x], rawData[[1]] == levels(rawData[[1]])[1])
        Experimental <- subset(rawData[x], rawData[[1]] == levels(rawData[[1]])[2])
        Eqv <- bartlett.test(formula(fml), data = rawData) # Bartlett equal variance test. p>0.5 means the variance between groups is equal.
        tTest <- t.test(Control, Experimental, var.equal = TRUE ,na.rm = TRUE)
        statsLst <- list(EqualVariance = Eqv, ttest = tTest)
      } else {"T-TEST CAN ONLY BE DONE FOR A TWO-GROUP COMPARISON (hint: try ANOVA/Tukey/Dunnett)."}
    } else if (tolower(Tp) %in% c("anova")){
      if (nlevels(rawData[[1]]) > 2){
        Eqv <- bartlett.test(formula(fml), data = rawData)  # Bartlett equal variance test. p>0.5 means the variance between groups is equal.
        statsLst <- list(EqualVariance = Eqv, ANOVA = anova(Mdl))
        statsLst
      } else {"USE T-TEST FOR A TWO-GROUP COMPARISON"}
    } else if (tolower(Tp) %in% c("tukey")){
      if (nlevels(rawData[[1]]) > 2){
        Eqv <- bartlett.test(formula(fml), data = rawData)  # Bartlett equal variance test. p>0.5 means the variance between groups is equal.
        statsLst <- list(EqualVariance = Eqv, ANOVA = anova(Mdl), Tukey = TukeyHSD(Mdl))
        statsLst
      } else {"USE T-TEST FOR A TWO-GROUP COMPARISON"}
    } else if (tolower(Tp) %in% c("dunnett", "dunnett\'s", "dunnetts")){
      if (nlevels(rawData[[1]]) > 2){
        Eqv <- bartlett.test(formula(fml), data = rawData)  # Bartlett equal variance test. p>0.5 means the variance between groups is equal.
        var <- cNm[1]
        arg <- list("Dunnett")
        names(arg) <- var
        mcp <- do.call(mcp, arg)
        statsLst <- list(EqualVariance = Eqv, ANOVA = anova(Mdl), Dunnett = summary(glht(Mdl, linfct = mcp)))
        statsLst
      } else {"USE T-TEST FOR A TWO-GROUP COMPARISON"}
    } else {
      "ERROR: CHECK YOUR STATS TEST."
    }
  },  simplify = FALSE)
  )
  sink() # end the dump

  cat("Done!\n") # final message
}
