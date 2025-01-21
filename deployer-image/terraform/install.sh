#!/bin/sh -eu

TF_CMD="terraform"
AUTO_APPROVE=""
ENABLE_AUTO_APPROVE=0

if [ "${1:-}" == "--auto-approve" ]; then
    AUTO_APPROVE="-auto-approve"
    ENABLE_AUTO_APPROVE=1
fi

function log(){
    echo $(date +%H:%M:%S) $*
}

function exit_if_error(){
    if [ $? -ne 0 ]; then
        log $*
        exit 1
    fi
}

function check_tf_cmd(){
    if command -v $TF_CMD &> /dev/null
    then
        return
    fi
    TF_CMD="tofu"
    if command -v $TF_CMD &> /dev/null
    then
        return
    fi
    exit_if_error 2 "Terraform/tofu binary not found"
}

function verify_aws_cli_version(){
    # check if aws cli version is > 2.0.0
    AWS_CLI_VERSION=$(aws --version | cut -d/ -f2 | cut -d. -f1)
    if [ $AWS_CLI_VERSION -lt 2 ]; then
        exit_if_error 4 "AWS CLI version must be > 2.0.0"
    fi
}

function install_helm(){
    if command -v helm &> /dev/null
    then
        return
    fi
    log "Installing helm"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
}

function install_kubectl(){
    if command -v kubectl &> /dev/null
    then
        return
    fi
    log "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/kubectl
}

function prepare(){
    check_tf_cmd
    verify_aws_cli_version
    install_kubectl
    install_helm

    log "Using $TF_CMD"
    # check_for auto.tfvars

    if [ ! -f "*.auto.tfvars" ]; then
        exit_if_error 3 "auto.tfvars not found"
        return
    fi
}

function init(){
    $TF_CMD init
}

function plan(){
    # if ENABLE_AUTO_APPROVE is set, then run apply
    if [ $ENABLE_AUTO_APPROVE -eq 1 ]; then
        log "Skipping plan and running apply"
        return
    fi
    $TF_CMD plan
}

function install(){
    log "Running apply"
    $TF_CMD apply $AUTO_APPROVE
    log "Installation complete"
}

function main(){
    prepare
    init
    plan
    install
}

main
