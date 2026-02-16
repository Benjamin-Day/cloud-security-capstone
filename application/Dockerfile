# Two stage build. Stage 1 is used to generate the executable.
# Stage 2 is used to run the produced executable. This allows 
# for a smaller and stripped down final image that contains
# only what is needed to run the code. The resulting image is 
# more secure and has less potential attack surfaces. 

# ====================== STAGE 1 ======================= #
# Required to use latest image for free tier of chaingaurd.
FROM cgr.dev/chainguard/go:latest AS builder

COPY ./api /api 

RUN cd /api && go mod download && go build -o api .

# ====================== STAGE 2 ======================= #
# Required to use latest image for free tier.
FROM cgr.dev/chainguard/glibc-dynamic:latest 

COPY --from=builder /api /usr/bin/

USER 1000

CMD ["/usr/bin/api"]

