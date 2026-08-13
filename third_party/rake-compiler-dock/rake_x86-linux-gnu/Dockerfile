FROM us-docker.pkg.dev/grpc-testing/testing-images-public/rake_base_x86-linux-gnu:2810c21e08c7a9cf1df5b2d83bbe65dfc201f56c@sha256:b5a2db94b4dda067038478a7bd97d0bbb485a15ad765cc02b4c330e16d02ec27

#=================
# Install ccache

# Install ccache from source since ccache 3.x packaged with most linux distributions
# does not support Redis backend for caching.
RUN curl -sSL -o ccache.tar.gz https://github.com/ccache/ccache/releases/download/v4.5.1/ccache-4.5.1.tar.gz \
    && tar -zxf ccache.tar.gz \
    && cd ccache-4.5.1 \
    && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DZSTD_FROM_INTERNET=ON -DHIREDIS_FROM_INTERNET=ON .. \
    && make -j4 && make install \
    && cd ../.. \
    && rm -rf ccache-4.5.1 ccache.tar.gz

