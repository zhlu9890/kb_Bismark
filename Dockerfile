FROM kbase/kbase:sdkbase2.latest
MAINTAINER Zhenyuan Lu
# -----------------------------------------
# In this section, you can install any system dependencies required
# to run your App.  For instance, you could place an apt-get update or
# install line here, a git checkout to download code, or run any other
# installation scripts.

RUN apt-get update

WORKDIR /kb/module

RUN wget --no-verbose https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh \
  && bash miniconda.sh -b -p miniconda

ENV PATH /kb/module/miniconda/bin:$PATH

RUN conda config --add channels bioconda \
  && conda config --add channels conda-forge \
  && conda install -y samtools=1.9 \
  && conda install -y bowtie2=2.3.4 \
  && conda install -y bismark=0.20.0

# download an inifile reader
RUN cpanm -i Config::IniFiles

# -----------------------------------------

COPY ./ /kb/module
RUN mkdir -p /kb/module/work
RUN chmod -R a+rw /kb/module

WORKDIR /kb/module

RUN make all

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
