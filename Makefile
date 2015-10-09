# Compare the PG29 nuclear, plastid and mitochondrion genomes
# Written by Shaun Jackman @sjackman.

# Number of threads
threads=8

all: \
	pg29-plastid.pg29-scaffolds.sort.bam.bai \
	pg29-plastid.pg29mt-scaffolds.sort.bam.bai \
	pg29-scaffolds.pg29-plastid.sort.bam.bai \
	pg29-scaffolds.pg29mt-scaffolds.sort.bam.bai \
	pg29mt-scaffolds.pg29-plastid.sort.bam.bai \
	pg29mt-scaffolds.pg29-scaffolds.sort.bam.bai \
	pg29-plastid.pg29-scaffolds.swap.sort.bam.bai \
	pg29mt-scaffolds.pg29-scaffolds.swap.sort.bam.bai \
	pg29.identity.tsv \
	pg29.swap.identity.tsv \
	pg29-plastid.pg29-scaffolds.sort.paf.tsv \
	pg29-plastid.pg29mt-scaffolds.sort.paf.tsv \
	pg29-scaffolds.pg29-plastid.sort.paf.tsv \
	pg29-scaffolds.pg29mt-scaffolds.sort.paf.tsv \
	pg29mt-scaffolds.pg29-plastid.sort.paf.tsv \
	pg29mt-scaffolds.pg29-scaffolds.sort.paf.tsv \
	pg29-plastid.pg29-scaffolds.swap.sort.paf.tsv \
	pg29mt-scaffolds.pg29-scaffolds.swap.sort.paf.tsv \
	pg-odna-transfer.html

.PHONY: all
.DELETE_ON_ERROR:
.SECONDARY:

# Align to the whole genome using BWA-MEM
pg29-scaffolds.%.sam: pg29-scaffolds.fa %.fa
	biomake threads=$(threads) ref=pg29-scaffolds $@

# Align to the plastid using BWA-MEM
pg29-plastid.%.sam: pg29-plastid.fa %.fa
	biomake threads=$(threads) ref=pg29-plastid $@

# Align to the mitochondrion using BWA-MEM
pg29mt-scaffolds.%.sam: pg29mt-scaffolds.fa %.fa
	biomake threads=$(threads) ref=pg29mt-scaffolds $@

# Swap the target and query of a SAM file
%.pg29-scaffolds.swap.sam: pg29-scaffolds.fa %.fa.fai pg29-scaffolds.%.sam
	samskrit-swap $^ |samtools calmd - $*.fa >$@

# Sort a SAM file and create a BAM file
%.sort.bam: %.sam
	$(samtools) view -Su $< |$(samtools) sort - $*.sort

# Remove perfectly identical alignments
%.imperfect.sort.bam: %.sort.bam
	samtools view -hF4 $< |grep -v 'NM:i:0' |samtools view -bo $@ -

# Index a BAM file
%.bam.bai: %.bam
	samtools index $<

# Tabulate alignment statistics
pg29.identity.tsv: \
		pg29-plastid.pg29-scaffolds.sort.bam \
		pg29-plastid.pg29mt-scaffolds.sort.bam \
		pg29-scaffolds.pg29-plastid.sort.bam \
		pg29-scaffolds.pg29mt-scaffolds.sort.bam \
		pg29mt-scaffolds.pg29-plastid.sort.bam \
		pg29mt-scaffolds.pg29-scaffolds.sort.bam
	samskrit-identity $^ >$@

# Tabulate alignment statistics of swapped alignments
pg29.swap.identity.tsv: \
		pg29-plastid.pg29-scaffolds.swap.sort.bam \
		pg29mt-scaffolds.pg29-scaffolds.swap.sort.bam
	samskrit-identity $^ >$@

# Convert BAM format to pairwise-alignment-format (PAF) using htsbox
%.paf: %.bam
	htsbox samview -p $< >$@

# Convert PAF format to TSV format
%.paf.tsv: %.paf
	(printf "qname\tqlength\tqstart\tqend\tstrand\ttname\ttlength\ttstart\ttend\tdivergence\tmapq\tattributes\n"; \
		awk 'NF == 12' $<) >$@

# Render RMarkdown to HTML
%.html: %.rmd
	Rscript -e 'rmarkdown::render("$<")'

# Dependencies
pg-odna-transfer.html: pg29-scaffolds.pg29-plastid.sort.paf.tsv pg29-scaffolds.pg29mt-scaffolds.sort.paf.tsv
