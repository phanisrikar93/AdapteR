% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wald_wolfowitz.R
\name{WaldWolftest2s}
\alias{WaldWolftest2s}
\title{Performs the Wald-Wolfowitz two sample test.}
\usage{
WaldWolftest2s(vFLvector, vFLvector2)
}
\arguments{
\item{x}{a FLVector containing the observations.}

\item{y}{a FLVector containing the observations.}
}
\value{
A list with class "htest" outputting the corresponding WW statistic and P Values.
}
\description{
Performs the Wald-Wolfowitz two sample test.
}
\examples{
tbl1 <- FLTable(getTestTableName("tblWW2SMulti"),
                "obsid",
                 whereconditions= "datasetid=1 and groupid=1")
tbl2 <- FLTable(getTestTableName("tblWW2SMulti"),
                "obsid",
                 whereconditions= "datasetid=1 and groupid=2")
v1 <- tbl1$num_val
v2 <- tbl2$num_val
result <- WaldWolftest2s(v1,v2)
result$statistic
result$p.value
}
