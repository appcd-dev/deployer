FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild:v2
COPY scripts/test.sh /scripts/test.sh
RUN chmod +x /scripts/test.sh
CMD ["/scripts/test.sh"]
