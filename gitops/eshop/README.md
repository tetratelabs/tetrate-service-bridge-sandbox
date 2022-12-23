# eShop demo application

This is a demo application that can be used to play with tenancy in TSB as well as the
telemetry parts of the product.

It consists of two applications:

* `eshop`: Contains the `eshop` and `checkout` namespaces.
* `payments`: Contains the `payments` namespaces.

The `payments` service is configured to introduce a 200ms latency, and the `checkout`
service is configured to fail 20% of the requests.  
The `eshop` ingress gateway is also configured to rate-limit to a max of 3 requests per
second per unique client address, and with WAF features enabled enforcing the Core Rule Set.

![eshop-topology](topology.png)

By default, it uses a demo LDAP as the Identity provider, and the following users
are configured. However, custom users can be designated as owners of the different applications
by configuring the environment variables as explained in the table at the end.

* `nacx/nacx-pass`: Is a Creator on the eshop tenant.
* `zack/zack-pass`: Is the owner of the eshop workspace.
* `wusheng/wusheng-pass`: Is the owner of the payments workspace.

## Example requests to showcase WAF

Get the address of the eShop ingress gateway as follows:

```bash
export ESHOP_GW=$(kubectl -n eshop get svc tsb-gateway-eshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Example malicious requests rejected by the WAF:

```bash
# XSS in the query parameters
curl -i -H "Host: eshop.tetrate.io" -H "X-B3-Sampled: 1" \
    "http://${ESHOP_GW}/proxy/orders?arg=<script>alert(0)</script>"

# SQL Injection in the request payload (leverages request body inspection)
curl -i -X POST -H "Host: eshop.tetrate.io" \
    --data "1%27%20ORDER%20BY%203--%2B" -H "X-B3-Sampled: 1" \
    http://${ESHOP_GW}/proxy/orders

# Vulnerability scanner detection
curl -i -H "Host: eshop.tetrate.io" -H "X-B3-Sampled: 1" \
    --user-agent "Grabber/0.1 (X11; U; Linux i686; en-US; rv:1.7)" \
    http://${ESHOP_GW}/proxy/orders

# Custom rule that rejects an invalid ID
curl -i -H "Host: eshop.tetrate.io" -H "X-B3-Sampled: 1" \
    "http://${ESHOP_GW}/proxy/orders?id=0"
```