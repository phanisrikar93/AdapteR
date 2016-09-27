
NULL

#' Kruskal-Wallis Rank Sum Test
#'
#' Performs a Kruskal-Wallis rank sum test.
#'
#' @param x FLVector with data values
#' @param g FLVector giving the group for the 
#' corresponding elements of y
#' @param formula a formula of the form response ~ group 
#' where response gives the data values and group a vector or factor 
#' of the corresponding groups.
#' Not applicable if FLVector is input.
#' @param data FLTable or FLTableMD objects.
#' @param subset Not currently used.
#' @param na.action na values omitted always.
#' @param ... The additional arguments used by FL function:
#' \code{whereconditions} WhereConditions to subset data
#' \code{GroupBy} Column names defining the different groups in data, if any.
#' @return A list with class \code{htest}.
#' A list of \code{htest} objects if the input is a FLTableMD object.
#' @examples
#' x <- c(2.9, 3.0, 2.5, 2.6, 3.2) # normal subjects
#' y <- c(3.8, 2.7, 4.0, 2.4)      # with obstructive airway disease
#' z <- c(2.8, 3.4, 3.7, 2.2, 2.0) # with asbestosis
#' x <- c(x, y, z)
#' g <- factor(rep(1:3, c(5, 4, 5)),
#'             labels = c("Normal subjects",
#'                        "Subjects with obstructive airway disease",
#'                        "Subjects with asbestosis"))
#' x <- as.FLVector(x)
#' g <- as.FLVector(g)
#' result1 <- kruskal.test(x, g)
#' print(result1)
#' FLTableObj <- as.FLTable(airquality,tableName="ARBaseTestTempTable",drop=TRUE)
#' result2 <- kruskal.test(Ozone ~ Month, data = FLTableObj)
#' print(result2)
#' @export
kruskal.test.FLVector <- function(x,g,...){
    if(!is.FLVector(g) && is.numeric(g))
        g <- as.FLVector(g)
    if(!is.FLVector(g))
        stop("g should be FLVector \n ")
    if(length(x)!=length(g))
        stop("x,g should have same length \n ")

    DNAME <- paste0(deparse(substitute(x))," and ",
                    deparse(substitute(g)))
    vView <- gen_view_name("Kruskal")
    vSelect <- constructUnionSQL(pFrom=c(a=constructSelect(x),
                                        b=constructSelect(g)),
                                 pSelect=list(a=c(DatasetID=1,
                                                ObsID="a.vectorIndexColumn",
                                                groupID=1,
                                                Num_Val="a.vectorValueColumn"),
                                              b=c(DatasetID=1,
                                                ObsID="a.vectorIndexColumn",
                                                groupID=2,
                                                Num_Val="b.vectorValueColumn")))

    vtemp <- createView(vView,pSelect=vSelect)

    vtable <- FLTableMD(vView,
                        group_id_colname="DatasetID",
                        obs_id_colname="ObsID")
    return(friedman.test(Num_Val~groupID,
                        data=vtable,
                        data.name=DNAME))
}


## S3 overload not working for default R calls:
## Error: Evaluation nested deeply.
## Becasuse stats comes after AdapteR in search path.


## S4 implementation because S3 not working for formula input case.
setGeneric("kruskal.test",
    function(formula, data,
            subset=TRUE, 
            na.action=getOption("na.action"),
            ...)
        standardGeneric("kruskal.test"))

## Not working: Environments related error.
## In the default R implementation, environments
## are used.
setMethod("kruskal.test",
        signature(formula="formula", 
                  data="ANY"),
        function(formula, data,
                subset=TRUE, 
                na.action=getOption("na.action"),
                ...){
                    return(stats::kruskal.test(formula=formula,
                                            data=data,
                                            subset=subset,
                                            na.action=na.action,
                                            ...))
                })

setMethod("kruskal.test",
        signature(formula="formula", 
                  data="FLTable"),
        function(formula, data,
                subset=TRUE, 
                na.action=getOption("na.action"),
                ...){
                    data <- setAlias(data,"")
                    connection <- getOption("connectionFL")
                    if(data@isDeep){
                        vSampleIDColname <- getVariables(data)[["var_id_colname"]]
                        vValueColname <- getVariables(data)[["cell_val_colname"]]
                    }
                    else{
                        vallVars <- all.vars(formula)
                        if(any(!vallVars %in% colnames(data)))
                            stop("columns specified in formula not in data \n ")
                        vSampleIDColname <- vallVars[2]
                        vValueColname <- vallVars[1]
                    }
                    vdata.name <- list(...)[["data.name"]]
                    if(is.null(vdata.name))
                        vdata.name <- paste0(vValueColname," by ",vSampleIDColname)
                    vobsIDCol <- getVariables(data)[["obs_id_colname"]]

                    # vgroupCols <- unique(c(vobsIDCol,list(...)[["GroupBy"]]))
                    vgroupCols <- unique(c(getVariables(data)[["group_id_colname"]],
                                        list(...)[["GroupBy"]]))
                    if(is.wideFLTable(data) &&
                        any(!setdiff(vgroupCols,vobsIDCol) %in% colnames(data)))
                        stop("columns specified in GroupBy not in data \n ")
                    vgrp <- paste0(vgroupCols,collapse=",")
                    if(!length(vgroupCols)>0)
                        vgrp <- NULL

                    ret <- sqlStoredProc(connection,
                                         "FLKWTest",
                                         TableName = getTableNameSlot(data),
                                         ValueColname = vValueColname,
                                         SampleIDColName = vSampleIDColname,
                                         WhereClause = list(...)[["whereconditions"]],
                                         GroupBy = vgrp,
                                         TableOutput = 1,
                                         outputParameter = c(ResultTable = 'a')
                                        )
                    ret <- as.character(ret[1,1])

                    VarID <- c(statistic="TEST_STAT",
                                p.value="P_VALUE")
                    vdf <- sqlQuery(connection,
                                        paste0("SELECT COUNT(DISTINCT a.",
                                                    vSampleIDColname,")-1 AS df \n ",
                                               " FROM ",getTableNameSlot(data)," a \n ",
                                               constructWhere(list(...)[["whereconditions"]])," \n ",
                                               ifelse(length(setdiff(vgrp,""))>0,
                                                        paste0("GROUP BY ",vgrp, " \n "),""),
                                               ifelse(length(setdiff(vgrp,""))>0,
                                                        paste0("ORDER BY ",vgrp),"")
                                            )
                                    )
                    vdf <- vdf[[1]]
                    vres <- sqlQuery(connection,
                                    paste0("SELECT ",paste0(VarID,collapse=",")," \n ",
                                            "FROM ",ret," \n ",
                                            ifelse(length(setdiff(vgrp,""))>0,
                                                    paste0("ORDER BY ",vgrp),"")))

                    vres <- cbind(groupID=1:nrow(vres),vres)
                    colnames(vres) <- c("groupID",names(VarID))

                    vresList <- dlply(vres,"groupID",
                                    function(x){
                                        vtemp <- list(statistic=c("Kruskal-Wallis chi-squared"=x[["statistic"]]),
                                                      parameter=c(df=vdf[x[["groupID"]]]),
                                                      p.value=x[["p.value"]],
                                                      method="Kruskal-Wallis rank sum test",
                                                      data.name=vdata.name
                                                      )
                                        class(vtemp) <- "htest"
                                        return(vtemp)
                                    })
                    names(vresList) <- 1:length(vresList)
                    if(length(vresList)==1)
                        vresList <- vresList[[1]]
                    vtemp <- dropView(getTableNameSlot(data))
                    return(vresList)
    })