# Tetrate Service Bridge Sandbox Release Notes

## [1.4.0](https://github.com/smarunich/tetrate-service-bridge-sandbox/compare/v1.3.1...v1.4.0) (2022-07-29)

### TSB Changes
* [Revision istio Control Plane](https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/revisioned_istio#sidecar-injection) Added  
* * Sidecar Injection example `istio.io/rev: enabled=tsb-stable`
* * Under Ingess/Egress and Tier1 Gateway spec configure `revision: tsb-stable`
* 

### Bug Fixes
* Decoupled cloud role dependency, azure/gcp is now optional(only used if region has index > 0)
* 


### Not Currently Supported
* Multiple Clusters under same Region for same Cloud
* 