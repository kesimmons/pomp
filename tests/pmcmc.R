library(pomp)
library(reshape2)
library(plyr)
library(magrittr)

pdf(file="pmcmc.pdf")

set.seed(1178744046L)

pompExample(ou2)

try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(rw.sd=c(alpha.2=0.01,alpha.3=0.01),rw.var=3,scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(rw.var=c(3,2,5,1),scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(rw.var=matrix(c(3,2,5,1),2,2,dimnames=list(c("alpha.2","alpha.3"),c("alpha.3","alpha.2"))),scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(rw.var=matrix(c(3,2,5,1,5,5),2,3,dimnames=list(c("alpha.2","alpha.3"),c("alpha.3","alpha.2","bob"))),scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(rw.sd=c(0.01,0.01),scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.rw.adaptive(rw.sd=c(alpha.2=0.01,alpha.3=0.01),target=3,scale.start=50,shape.start=50)))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.diag.rw(rw.sd=c("A","B")),verbose=TRUE))
try(pmcmc(ou2,Nmcmc=2,Np=100,proposal=mvn.diag.rw(rw.sd=c(0.01,0.01)),verbose=TRUE))
pmcmc(ou2,Nmcmc=2,Np=100,
      proposal=mvn.rw.adaptive(
          rw.sd=c(alpha.2=0.01,alpha.3=0.01),
          scale.start=50,shape.start=50)) -> ignore

dprior.ou2 <- function (params, log, ...) {
    f <- sum(dunif(params,min=coef(ou2)-1,max=coef(ou2)+1,log=TRUE))
    if (log) f else exp(f)
}

capture.output(
    pmcmc(
        pomp(ou2,dprior=dprior.ou2),
        Nmcmc=20,
        proposal=mvn.diag.rw(c(alpha.2=0.001,alpha.3=0.001)),
        Np=100,
        verbose=TRUE
    ) %>%
    continue(Nmcmc=20) -> f1
) -> out
stopifnot(length(out)==41)
stopifnot(sum(grepl("PMCMC iteration",out))==21)
stopifnot(sum(grepl("acceptance ratio",out))==20)
f1 %>% plot()
try(continue(f1,Np=function(k)if(k<10) "B" else 500))
try(continue(f1,Np=function(k)if(k<10) c(10,-20) else 500))

f1 %>% pfilter() %>%
    pmcmc(
        Nmcmc=20,
        proposal=mvn.diag.rw(c(alpha.2=0.01,alpha.3=0.01)),
        max.fail=100,
        verbose=FALSE
    ) -> f2
f2 %>% pmcmc() -> f3
f3 %>% continue(Nmcmc=20) -> f4

plot(c(f2,f3))

try(ff <- c(f3,f4))

if (Sys.getenv("FULL_TESTS")=="yes") {
    f2a <- pmcmc(f1,Nmcmc=300,Np=100,verbose=FALSE)
    plot(f2a)
    runs <- rle(as.numeric(conv.rec(f2a,'loglik')))$lengths
    plot(sort(runs))
    acf(conv.rec(f2a,c("alpha.2","alpha.3")))
}

ou2 %>%
    pomp(dprior=function (params, log, ...) {
        f <- sum(dnorm(params,mean=coef(ou2),sd=1,log=TRUE))
        if (log) f else exp(f)
    }) %>%
    pmcmc(
        Nmcmc=20,
        proposal=mvn.diag.rw(c(alpha.2=0.001,alpha.3=0.001)),
        Np=100,
        verbose=FALSE
    ) -> f5
f5 %>% continue(Nmcmc=20) -> f6
plot(f6)
invisible(logLik(f6))
invisible(conv.rec(c(f6)))

ff <- c(f4,f6)
plot(ff)
plot(conv.rec(ff,c("alpha.2","alpha.3","loglik")))
invisible(filter.traj(ff))

ff <- c(f2,f3)
ff <- c(ff)

try(ff <- c(ff,f4,f6))
try(ff <- c(f4,ou2))
try(ff <- c(ff,ou2))

plot(ff <- c(ff,f5))
invisible(covmat(ff))
plot(conv.rec(c(f2,ff),c("alpha.2","alpha.3")))
plot(conv.rec(ff[2],c("alpha.2")))
plot(conv.rec(ff[2:3],c("alpha.3")))
plot(window(conv.rec(ff[2:3],c("alpha.3")),thin=3,start=2))
plot(conv.rec(ff[[3]],c("alpha.3")))

sig <- array(data=c(0.1,-0.1,0,0.01),
             dim=c(2,2),
             dimnames=list(
                 c("alpha.2","alpha.3"),
                 c("alpha.2","alpha.3")))
sig <- crossprod(sig)

ou2 %>%
    pomp(dprior=function (params, log, ...) {
        f <- sum(dnorm(params,mean=coef(ou2),sd=1,log=TRUE))
        if (log) f else exp(f)
    }) %>%
    pmcmc(
        Nmcmc=30,
        proposal=mvn.rw(sig),
        Np=100,
        verbose=FALSE
    ) -> f7
plot(f7)

ou2 %>%
    pomp(dprior=function (params, log, ...) {
        f <- sum(dnorm(params,mean=coef(ou2),sd=1,log=TRUE))
        if (log) f else exp(f)
    }) %>%
    pmcmc(
        Nmcmc=50,Np=500,verbose=FALSE,
        proposal=mvn.rw.adaptive(rw.sd=c(alpha.2=0.01,alpha.3=0.01),
                                 scale.start=50,shape.start=50)) -> f8
f8 %<>% continue(Nmcmc=50,proposal=mvn.rw(covmat(f8)),verbose=FALSE)
plot(f8)

library(coda)

f8 %>% conv.rec(c("alpha.2","alpha.3")) %>%
    window(start=50) -> trace
trace <- window(trace,thin=5)
plot(trace)

library(ggplot2)

f8 %>%
    filter.traj() %>%
    melt() %>%
    subset(rep %% 5 == 0) %>%
    ddply(~time+variable,summarize,
          prob=c(0.05,0.5,0.95),
          q=quantile(value,prob=prob)
          ) %>%
    ggplot(aes(x=time,y=q,group=prob,color=factor(prob)))+
    geom_line()+facet_grid(variable~.)+labs(color="quantile",y="value")+
    theme_bw()

try(ou2 %>%
    pomp(dprior=function (params, log, ...) {
        stop("oops!")
    }) %>%
    pmcmc(
        Nmcmc=50,Np=500,verbose=FALSE,
        proposal=mvn.diag.rw(c(alpha.2=0.01,alpha.3=0.01))))
neval <- 0
try(ou2 %>%
    pomp(dprior=function (params, log, ...) {
        neval <<- neval+1
        if (neval>2) stop("yipes!") else if (log) 0 else 1
    }) %>%
    pmcmc(
        Nmcmc=50,Np=500,verbose=FALSE,
        proposal=mvn.diag.rw(c(alpha.2=0.01,alpha.3=0.01))))
try(ou2 %>% pmcmc(Nmcmc=50,Np=500,verbose=FALSE,
                  proposal=function(theta,...)stop("eeps!")))
try(ou2 %>% pmcmc(Nmcmc=50,Np=500,verbose=FALSE,
                  proposal=function(theta,...) {
                      stop("yow!")
                  }))
neval <- 0
try(ou2 %>% pmcmc(Nmcmc=50,Np=500,verbose=FALSE,
                  proposal=function(theta,...) {
                      neval <<- neval+1
                      if (neval>1) stop("yikes!") else theta
                  }))

dev.off()
