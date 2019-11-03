export REPO_DIR = $(shell pwd)
export SOLC_VERSION = 0.5.7

root_contracts := ManagedLoanService ManagedLoan
contracts := $(root_contracts) ## All contract names

sol := $(shell find contracts -name '*.sol' -not -name '.*' ) ## All Solidity files
json := $(foreach contract,$(contracts),evm/$(contract).json) ## All JSON files
abi := $(foreach contract,$(contracts),abi/$(contract).go) ## All ABI files
myth_analyses := $(foreach solFile,$(sol),analysis/$(subst contracts/,,$(basename $(solFile))).myth.md)
flat := $(foreach solFile,$(sol),flat/$(subst contracts/,,$(solFile)))

all: json abi

abi: $(abi)
json: $(json)
flat: $(flat)

# test: abi
# 	go test ./tests -tags all

# fuzz: abi
# 	go test ./tests -v -tags fuzz -args -decimals=$(decimals) -runs=$(runs)

clean:
	rm -rf abi evm sol-coverage-evm analysis flat

deploy: json
	scripts/deploy

create: json
	scripts/create

deposit: json
	scripts/deposit

sizes: json
	scripts/sizes $(json)

check: $(sol)
	slither contracts
triage-check: $(sol)
	slither --triage-mode contracts

# Invoke this with parallel builds off: `make -j1 mythril`
# If you have parallel make turned on, this won't work right, because mythril.
mythril: $(myth_analyses)


fmt:
	npx solium -d contracts/ --fix
	npx solium -d tests/echidna/ --fix

run-geth:
	docker run -it --rm -p 8545:8501 0xorg/devnet

# Pattern rule: generate ABI files
abi/%.go: evm/%.json genABI.go
	go run genABI.go $*

# solc recipe template for building all the JSON outputs.
# To use as a build recipe, optimized for (e.g.) 1000 runs,
# use "$(call solc,1000)" in your recipe.
define solc
@mkdir -p evm
solc --allow-paths $(REPO_DIR)/contracts --optimize --optimize-runs $1 \
     --combined-json=abi,bin,bin-runtime,srcmap,srcmap-runtime,userdoc,devdoc \
     $< > $@
endef

evm/ManagedLoanService.json : contracts/ManagedLoanService.sol $(sol)
	$(call solc,100000)

evm/ManagedLoan.json: contracts/ManagedLoan.sol $(sol)
	$(call solc,10000)


# myth runs mythril, and plops its output in the "analysis" directory
define myth
@mkdir -p $(@D)
myth a $< > $@
endef

# By default, don't specify the contract name
analysis/%.myth.md: contracts/%.sol $(sol)
	$(call myth)

define myth_specific
@mkdir -p $(@D)
myth a $<:$1 > $@
endef

flat/%.sol: contracts/%.sol
	@mkdir -p $(@D)
	go run github.com/coburncoburn/SolidityFlattery -input $< -output $(basename $@)

# Mark "action" targets PHONY, to save occasional headaches.
.PHONY: all clean json abi test fuzz check triage-check mythril fmt run-geth sizes flat
