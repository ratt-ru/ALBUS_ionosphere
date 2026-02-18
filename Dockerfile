# ubuntu 18.04... for now
# FROM kernsuite/base:6
FROM kernsuite/base:7

# need to test whether we can migrate to GCC 10
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    python3-all \
    ipython3 \
    python3-ipdb \
    wcslib-dev \
    python3-astropy \
    python3-casacore \
    casacore-data \
    curl \
    wget \
    rsync \
    python3-pycurl \
    python3-matplotlib \
    python3-numpy \
    python3-ephem \
    f2c \
    libf2c2-dev \
    bison \
    flex \
    python3-urllib3 \
    unzip \
    python3-nose \
    python3-requests \
    python3-pip \
    cmake \
    gfortran \
    liblapacke-dev \
    software-properties-common \
    python3.10 python3.10-venv python3.10-dev




RUN mkdir -p /optsoft/bin && \
    mkdir -p /optsoft/lib && \
    mkdir -p /optsoft/src && \
    mkdir -p /optsoft/include

ENV PATH $PATH:/optsoft/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/optsoft/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:/optsoft/include
ENV CPLUS_INCLUDE_PATH $C_INCLUDE_PATH:/optsoft/include


# ---------- Build RNXCMP from source into /optsoft ---------- 
RUN mkdir /src
ADD RNXCMP_4.1.0_src.tar.gz /src/
WORKDIR /src/RNXCMP_4.1.0_src/source
RUN gcc -ansi -O2 -static rnx2crx.c -o /optsoft/bin/RNX2CRX && \
    gcc -ansi -O2 -static crx2rnx.c -o /optsoft/bin/CRX2RNX && \
    ln -s /optsoft/bin/CRX2RNX /optsoft/bin/crx2rnx && \
    ln -s /optsoft/bin/RNX2CRX /optsoft/bin/rnx2crx


# ---------- COMPILE ALBUS ----------
# Step 1 setup directory structure and move source code into container
# RUN mkdir -p /src/ALBUS
ENV ALBUSPATH /src/ALBUS

ADD source_dir $ALBUSPATH/source_dir
ADD pyproject.toml $ALBUSPATH/pyproject.toml 
ADD README.md $ALBUSPATH/README.md
ADD CMakeLists.txt $ALBUSPATH/CMakeLists.txt
ADD AlbusIonosphere.cxx $ALBUSPATH/AlbusIonosphere.cxx



## Configure and run albus
WORKDIR /src/ALBUS

RUN python3.10 -m venv build_env 
SHELL ["/bin/bash", "-c"]
RUN source build_env/bin/activate && echo "Environment activated"
RUN build_env/bin/pip install -U pip build
RUN build_env/bin/pip install --upgrade pip
WORKDIR /src/ALBUS
RUN build_env/bin/pip install -U pip setuptools wheel
## since there is no build isolation this needs to installled before build
RUN build_env/bin/pip install scikit-build-core[pyproject] numpy==1.21

RUN build_env/bin/python -m pip install --no-build-isolation .

#needed no other way, not set by system, needs to be declared before runing albus imported as a variable
ENV PYTHONPATH "/src/ALBUS/build_env/lib/python3.10/site-packages/share:$PYTHONPATH"




ENTRYPOINT [ "/usr/bin/python3.6" ]
# print some default stuffs
ENV HELPSTRING "docker run -v <absolute path to gfzrnx>:/optsoft/bin/gfzrnx "\
"-v <absolute path to your waterhole with scripts>:/albus_waterhole "\
"--workdir /albus_waterhole "\
"--rm "\
"--user $(id -u <your user>):$(id -g <your user>) "\
"albus:latest <path to script mounted inside the waterhole>"
CMD [ "-c", "import AlbusIonosphere; import os; import pkg_resources; print('ALBUS\\n====='); print(AlbusIonosphere.__doc__); version = pkg_resources.require('AlbusIonosphere')[0].version; print('Version {}'.format(version)); print('Usage: ' + os.environ['HELPSTRING'])" ]
# crack the bubbly: this hog is airborne!



