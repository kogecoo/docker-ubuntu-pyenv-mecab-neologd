FROM bopen/ubuntu-pyenv:18.04

COPY requirements-setup.txt mecab-revision.txt python-versions.txt /python-mecab-neologd-settings/

# Install MeCab
RUN apt-get update && apt-get install -y file
# mecab libmecab-dev mecab-ipadic-utf8

# Install neologd dictionary
RUN git clone git://github.com/taku910/mecab /tmp/mecab \
  && cd /tmp/mecab/mecab \
  && git checkout -b tmp `cat /python-mecab-neologd-settings/mecab-revision.txt` \
  && ./configure  --enable-utf8-only \
  && make \
  && make check \
  && make install \
  && ldconfig

RUN cd /tmp/mecab/mecab-ipadic \
  && ./configure --with-charset=utf8 \
  && make \
  && make install

# Install neologd dictionary
RUN git clone git://github.com/neologd/mecab-ipadic-neologd /tmp/neologd && cd /tmp/neologd && ./bin/install-mecab-ipadic-neologd -n -y # -a
RUN dicd=`mecab-config --dicdir`; esc=$(echo $dicd | sed -e "s/\\//\\\\\//g") ; sed -i -e 's/dicdir\ \=\ /dicdir\ \=\ '$esc'\/mecab-ipadic-neologd\n;dicdir\ \=\ /' `mecab-config --prefix`/etc/mecabrc

RUN for v in `cat /python-mecab-neologd-settings/python-versions.txt`; do pyenv global $v; pip install -r /python-mecab-neologd-settings/requirements-setup.txt; done \
  && find $PYENV_ROOT/versions -type d '(' -name '__pycache__' -o -name 'test' -o -name 'tests' ')' -exec rm -rf '{}' + \
  && find $PYENV_ROOT/versions -type f '(' -name '*.pyo' -o -name '*.exe' ')' -exec rm -f '{}' + \
&& rm -rf /tmp/*
