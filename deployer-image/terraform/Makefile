deps: helm/package
	mkdir -p docs
	mkdir -p ./values/dex
	cp ../../../installation/on-prem/docs/*.md ./docs/
	cp ../../../installation/on-prem/values/images.yaml ./values/images.yaml
	cp -r ../../../installation/on-prem/modules/k8s_deps/values/* ./values
	cp ../../../installation/on-prem/install.sh ./
	cp -r ../../../installation/aws/namespace/values/dex/* ./values/dex/

build:
	helm dependency update ../../../installation/k8s/appcd-dist

helm/package: build
	helm package --destination . ../../../installation/k8s/appcd-dist