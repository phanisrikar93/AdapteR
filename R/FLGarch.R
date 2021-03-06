#' @export
setClass("FLGarch",
         slots = list(results = "list"))

#' @export
garch <- function (data=list(),order = c(1,1),type = "normal", ...) {
    UseMethod("garch", data)
}

#' @export
garch.default<-function (object,order = c(1,1),...) {
    if (!requireNamespace("tseries", quietly = TRUE)){
        stop("tseries package needed for Augmented Dickey Fuller test. Please install it.",
             call. = FALSE)
    }
    else return(tseries::garch(object,...))
}

## test case in test_garch.R.
#' \code{garch} estimates the parameters of an univariate Generalized Auto Regressive Conditional Heteroskedasticity (GARCH) model

#' The DB Lytix function called is FLGARCHpqUdt, FLARCHqUDT
#' and FLIGarchUdt depending on paramters  
#' @param data An object of class FLVector.
#' @param p Total Number of ARCH terms INTEGER,.
#' @param q Total  Number of GARCH terms.
#' @param Valtype .
#' @return \code{garch} returns a data.frame
#' @examples
#' flt <- FLTable("tblbac_return", "ID")
#' flmod <- garch(flt$stockreturn, order = c(1,1))
#' ARCHqUDT Example.
#' rv <- sqlQuery(connection, "SELECT stockprice  FROM tblbac")
#' flv <- as.FL(rv$stockprice)
#' flmod <- garch.FLVector(flv, order = c(0,1))
## IGARCH Example
#' rv <- sqlQuery(connection, "SELECT stockreturn FROM tblbac_return")
#' flv <- as.FL(rv$stockreturn)
#' flmod <- garch.FLVector(flv, order = c(1,1), type = "Integrated")
#' @export
garch.FLVector <- function(data,order = c(1,1),type = "normal", ...)
{
    callObject <- match.call()
    if(!is.FLVector(data)){
        stop("only applicable on FLVector")
    }
    if(is.null(list(...)[["ValueType"]]))
        Valtype = "R"
    else
        Valtype = list(...)[["ValueType"]]
    
    if(order[1] == 0){
        functionName <- "FLARCHqUDT"
        q <- order[2]
        vColname <- c(GroupID = 1,
                      q = q,
                      ValType = fquote(Valtype),
                      Val = "vectorValuecolumn")
        
        vsubset <- c("GroupID","q","ValType","Val")
    }
   
    if(order[1] >= 1){
        functionName <- "FLGARCHpqUdt"
        p <- order[1]
        q <- order[2]
        vColname <- c(GroupID = 1,
                      q = q,
                      p = p,
                      ValType = fquote(Valtype),
                      Val = "vectorValuecolumn")
        vsubset <- c("GroupID","q","p","ValType","Val") 
    }
    
    if(type == "Integrated"){
        functionName <- "FLIGarchUdt"
        p <- order[1]
        q <- order[2]
        vColname <- c(GroupID = 1,
                      q = q,
                      p = p,
                      Val = "vectorValuecolumn")
        vsubset <- c("GroupID","q","p","Val") 
    }
    
    
    ##pArg <- c(pD = degree)
    str <- constructUDTSQL(pViewColname = vColname,
                         pFuncName = functionName,
                         pOutColnames = c("a.*"),
                         pSelect = constructSelect(data),
                         ##pArgs = pArg,
                         pLocalOrderBy=c("GroupID", "val"),
                         pNest = TRUE,
                         pFromTableFlag = FALSE,
                         UDTInputSubset = vsubset)
    vdf <- sqlQuery(connection, str)
    vdf <- vdf[, -1]
        return(new("FLGarch",
                   results=list(call=callObject,
                                q = q,
                                vout = vdf )))   
}

#' @export
`$.FLGarch`<-function(object,property){
    parentObject <- unlist(strsplit(unlist(strsplit(as.character(sys.call()),
                            "(",fixed=T))[2],",",fixed=T))[1]
    vparamNameCol <- getMatrixUDTMapping("FLGarch")$argsPlatform["oParamName"]
    vparamValue <- getMatrixUDTMapping("FLGarch")$argsPlatform["oParamValue"]
    voutput <- object@results$vout
    if(property == "Alpha"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "Alpha1"])}
    if(property == "Beta"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "Beta1"])}
    if(property == "Gamma"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "Gamma"])}
    if(property == "Omega"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "Omega"])}
    if(property == "AIC"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "AIC"])}
    if(property == "SBC"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "SBC"])}
    if(property == "Variance"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "Variance"])}
    if(property == "ConvCrit"){
        return(voutput[[vparamValue]][voutput[vparamNameCol] == "ConvCrit"])}
}
 

setMethod("names", signature("FLGarch"), function(x) c("ConvCrit",
                                                       "Variance",
                                                       "SBC",
                                                       "AIC",
                                                       "Omega",
                                                       "Gamma",
                                                       "Beta",
                                                       "Alpha"))





#' @export
regimeshift <- function (data=list(),regimes = 2, ...) {
    UseMethod("regimeshift", data)
}
## test case in test_FLdifference.
#' \code{regimeshift} performs helps in identifying the parameters of the
#' Gaussian distribution and the probability that a given observation has been
#' drawn from a given distribution on FLVector objects.
#' The DB Lytix function called is FLRegimeShiftUdt. 
#' @param data An object of class FLVector.
#' @param regimes Total number of Regimes.
#' @return \code{regimeshift} returns a data.frame
#' @examples
#' vdf <-  sqlQuery(connection, "SELECT Num_Val FROM tblRegimeShift WHERE Groupid = 1 AND Obsid <500")
#' colnames(vdf) <- tolower(colnames(vdf))
#' flv <- as.FL(vdf$num_val)
#' flmod <- regimeshift(flv, regimes = 3)
#' @export
regimeshift.FLVector <- function(data,regimes = 2, ...)
{
    if(!is.FLVector(data)){
        stop("only applicable on FLVector")
    }

    functionName <- "FLRegimeShiftUdt"
    
    str <- constructUDTSQL(pViewColname = c(groupid = 1,
                                            val = "vectorValuecolumn",
                                            regimes=regimes),
                         pFuncName = functionName,
                         pOutColnames = c("a.*"),
                         pSelect = constructSelect(data),
                         pLocalOrderBy=c("groupid"),
                         pNest = TRUE,
                         pFromTableFlag = FALSE)
    vdf <- sqlQuery(connection, str)
    vdf <- vdf[,2:length(vdf)]
    names(vdf) <- c("Regime", "Mean", "StdDev", "Prob")
               
    return(vdf)
}
