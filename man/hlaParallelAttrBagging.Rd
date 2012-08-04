\name{hlaParallelAttrBagging}
\alias{hlaParallelAttrBagging}
\title{
	Build a HIBAG model via parallel computation
}
\description{
	To build an attribute bagging model for predicting HLA types via parallel computation
}
\usage{
hlaParallelAttrBagging(cl, hla, genotype, nclassifier=100, mtry=c("sqrt", "all", "one"),
	prune=TRUE, rm.na=TRUE, verbose=TRUE, verbose.detail=FALSE)
}
\arguments{
	\item{cl}{a cluster object, created by this package or by the package
		\link[parallel]{parallel} or \href{http://CRAN.R-project.org/package=snow}{snow}}
	\item{hla}{training HLA types, an object of \code{\link{hlaAlleleClass}}}
	\item{genotype}{training genotypes, a genotype object of \code{\link{hlaSNPGenoClass}}}
	\item{nclassifier}{the total number of individual classifiers}
	\item{mtry}{a character or a numeric value, the number of variables randomly sampled
		as candidates for each selection. See details}
	\item{prune}{if TRUE, to perform a parsimonious forward variable selection, otherwise,
		exhaustive forward variable selection. See details}
	\item{rm.na}{if TRUE, remove the samples with missing HLA types}
	\item{verbose}{if TRUE, show information}
	\item{verbose.detail}{if TRUE, show more information}
}
\details{
	\code{mtry} (the number of variables randomly sampled as candidates for each selection):
	\code{"sqrt"}, using the square root of the total number of candidate SNPs;
	\code{"all"}, using all candidate SNPs;
	\code{"one"}, using one SNP;
	\code{an integer}, specifying the number of candidate SNPs;
	\code{0 < r < 1}, the number of candidate SNPs is "r * the total number of SNPs".

	\code{prune}: there is no significant difference on accuracy between parsimonious and
exhaustive forward variable selections. If \code{prune = TRUE}, the searching algorithm
performs a parsimonious forward variable selection: if a new SNP predictor reduces the
current out-of-bag accuracy, then it is removed from the candidate SNP set for future searching.
Parsimonious selection helps to improve the computational efficiency by reducing the searching
times of non-informative SNP markers.
}
\value{
	Return an object of \code{\link{hlaAttrBagClass}}:
	\item{n.samp}{the total number of training samples}
	\item{n.snp}{the total number of candidate SNP predictors}
	\item{sample.id}{the sample IDs}
	\item{snp.id}{the SNP IDs}
	\item{snp.position}{SNP position in basepair}
	\item{snp.allele}{a vector of characters with the format of ``A allele/B allele''}
	\item{snp.allele.freq}{the allele frequencies}
	\item{hla.locus}{the name of HLA locus}
	\item{hla.allele}{the HLA alleles used in the model}
	\item{hla.freq}{the HLA allele frequencies}
	\item{model}{internal use}
}
\author{Xiuwen Zheng \email{zhengx@u.washington.edu}}
\seealso{
	\code{\link{hlaClose}}, \code{\link{summary.hlaAttrBagClass}}
}

\examples{
# load HLA types and SNP genotypes
data(hla.type.table, package="HIBAG")
data(hla.snp.geno, package="HIBAG")

# make a "hlaAlleleClass" object
hla.id <- "A"
hla <- hlaAllele(hla.type.table$sample.id, hla.type.table[, paste(hla.id, ".1", sep="")],
	hla.type.table[, paste(hla.id, ".2", sep="")], locus=hla.id)

# divide HLA types randomly
set.seed(100)
hlatab <- hlaSplitAllele(hla, train.prop=0.5)
names(hlatab)
# "training"   "validation"
summary(hlatab$training)
summary(hlatab$validation)

# SNP predictors within the flanking region on each side
region <- 500   # kb
snpid <- hlaFlankingSNP(hla.snp.geno$snp.id, hla.snp.geno$snp.position, hla.id, region*1000)
length(snpid)  # 275

# training and validation genotypes
train.geno <- hlaGenoSubset(hla.snp.geno, snp.sel=match(snpid, hla.snp.geno$snp.id),
	samp.sel=match(hlatab$training$value$sample.id, hla.snp.geno$sample.id))
test.geno <- hlaGenoSubset(hla.snp.geno,
	samp.sel=match(hlatab$validation$value$sample.id, hla.snp.geno$sample.id))


#############################################################################

library(parallel)
# Use option cl.core to choose an appropriate cluster size.
cl <- makeCluster(getOption("cl.cores", 2))
set.seed(100)

# train an attribute bagging model
# please try "nclassifier=25" or "nclassifier=100" when you use HIBAG for real data
model <- hlaParallelAttrBagging(cl, hlatab$training, train.geno, nclassifier=4)
summary(model)

# validation
pred <- predict(model, test.geno)
# compare
comp <- hlaCompareAllele(hlatab$validation, pred, allele.limit=model$hla.allele,
	call.threshold=0.5)
comp
# total.num.ind crt.num.ind crt.num.haplo  acc.ind acc.haplo call.threshold n.call call.rate
#            26          20            41 0.952381 0.9761905            0.5     21 0.8076923

# stop parallel nodes
stopCluster(cl)
}

\keyword{HLA}
\keyword{GWAS}
\keyword{genetics}