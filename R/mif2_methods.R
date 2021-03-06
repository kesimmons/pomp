## ancillary methods for working with 'mif2d.pomp' objects

setMethod('conv.rec','mif2d.pomp',
          function (object, pars, transform = FALSE, ...) {
              conv.rec.internal(object=object,pars=pars,transform=transform,...)
          }
          )

## mif2List class
setClass(
    'mif2List',
    contains='list',
    validity=function (object) {
        if (!all(sapply(object,is,'mif2d.pomp'))) {
            retval <- paste0(
                "error in ",sQuote("c"),
                ": dissimilar objects cannot be combined"
            )
            return(retval)
        }
        d <- sapply(object,function(x)dim(x@conv.rec))
        if (!all(apply(d,1,diff)==0)) {
            retval <- paste0(
                "error in ",sQuote("c"),
                ": to be combined, ",sQuote("mif2d.pomp"),
                " objects must equal numbers of iterations"
            )
            return(retval)
        }
        TRUE
    }
)

setMethod(
    'c',
    signature=signature(x='mif2d.pomp'),
    definition=function (x, ...) {
        y <- list(...)
        if (length(y)==0) {
            new("mif2List",list(x))
        } else {
            p <- sapply(y,is,'mif2d.pomp')
            pl <- sapply(y,is,'mif2List')
            if (!all(p||pl))
                stop("in ",sQuote("c"),": cannot mix ",sQuote("mif2d.pomp"),
                     " and non-",sQuote("mif2d.pomp")," objects",call.=FALSE)
            y[p] <- lapply(y[p],list)
            y[pl] <- lapply(y[pl],as,"list")
            new("mif2List",c(list(x),y,recursive=TRUE))
        }
    }
)

setMethod(
    'c',
    signature=signature(x='mif2List'),
    definition=function (x, ...) {
        y <- list(...)
        if (length(y)==0) {
            x
        } else {
            p <- sapply(y,is,'mif2d.pomp')
            pl <- sapply(y,is,'mif2List')
            if (!all(p||pl))
                stop("in ",sQuote("c"),": cannot mix ",sQuote("mif2d.pomp"),
                     " and non-",sQuote("mif2d.pomp")," objects",call.=FALSE)
            y[p] <- lapply(y[p],list)
            y[pl] <- lapply(y[pl],as,"list")
            new("mif2List",c(as(x,"list"),y,recursive=TRUE))
        }
    }
)

setMethod(
    "[",
    signature=signature(x="mif2List"),
    definition=function(x, i, ...) {
        new('mif2List',as(x,"list")[i])
    }
)

setMethod(
    'conv.rec',
    signature=signature(object='mif2List'),
    definition=function (object, ...) {
        lapply(object,conv.rec,...)
    }
)

setMethod(
    'coef',
    signature=signature(object='mif2List'),
    definition=function (object, ...) {
        do.call(rbind,lapply(object,coef,...))
    }
)

mif2.diagnostics <- function (z) {
    ## assumes that z is a list of mif2d.pomps with identical structure
    mar.multi <- c(0,5.1,0,2.1)
    oma.multi <- c(6,0,5,0)
    xx <- z[[1]]
    parnames <- names(coef(xx,transform=xx@transform))
    estnames <- parnames

    ## plot ESS and cond.loglik
    nplots <- 2
    n.per.page <- 2
    nc <- 1
    nr <- 2
    oldpar <- par(mar=mar.multi,oma=oma.multi,mfcol=c(2,1),
                  ask=dev.interactive(orNone=TRUE))
    on.exit(par(oldpar))

    time <- time(xx)
    dat <- sapply(z,eff.sample.size)
    matplot(
        y=dat,
        x=time,
        axes = FALSE,
        xlab = "",
        log='y',
        ylab = "eff. sample size",
        type = "l"
    )
    box()
    axis(2, xpd = NA)
    mtext("Filter diagnostics (last iteration)",side=3,line=2,outer=TRUE)

    dat <- sapply(z,cond.logLik)
    matplot(
        y=dat,
        x=time,
        axes = FALSE,
        xlab = "",
        log='',
        ylab = "cond. logLik",
        type = "l"
    )
    box()
    axis(2, xpd = NA)

    axis(1,xpd=NA)
    mtext("time",side=1,line=3)

    ## plot mif convergence diagnostics
    other.diagnostics <- c("loglik", "nfail")
    plotnames <- c(other.diagnostics,estnames)
    nplots <- length(plotnames)
    n.per.page <- min(nplots,10)
    nc <- if (n.per.page<=4) 1 else 2
    nr <- ceiling(n.per.page/nc)
    par(mar=mar.multi,oma=oma.multi,mfcol=c(nr,nc))
    ## on.exit(par(oldpar))
    low <- 1
    hi <- 0
    iteration <- seq(0,xx@Nmif)
    while (hi<nplots) {
        hi <- min(low+n.per.page-1,nplots)
        for (i in seq(from=low,to=hi,by=1)) {
            n <- i-low+1
            dat <- sapply(z,function(po,label) conv.rec(po,label),label=plotnames[i])
            matplot(
                y=dat,
                x=iteration,
                axes = FALSE,
                xlab = "",
                ylab = "",
                type = "l"
            )
            box()
            y.side <- 2
            axis(y.side,xpd=NA)
            mtext(plotnames[i],y.side,line=3)
            do.xax <- (n%%nr==0||n==n.per.page)
            if (do.xax) axis(1,xpd=NA)
            if (do.xax) mtext("MIF iteration",side=1,line=3)
        }
        low <- hi+1
        mtext("MIF2 convergence diagnostics",3,line=2,outer=TRUE)
    }
    invisible(NULL)
}

setMethod(
    "plot",
    "mif2d.pomp",
    function (x, y, ...) {
        if (!missing(y))
            warning("in ",sQuote("plot-mif2d.pomp"),": ",
                    sQuote("y")," is ignored",call.=FALSE)
        mif2.diagnostics(list(x))
    }
)

setMethod(
    "plot",
    signature=signature(x='mif2List'),
    definition=function (x, y, ...) {
        if (!missing(y))
            warning("in ",sQuote("plot-mif2d.pomp"),": ",
                    sQuote("y")," is ignored",call.=FALSE)
        mif2.diagnostics(x)
    }
)
