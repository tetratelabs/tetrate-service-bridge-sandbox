# eShop demo application

This is a demo application that can be used to play with tenancy in TSB as well as the
telemetry parts of the product.

It consists of two applications:

* `eshop`: Contains the `eshop` and `checkout` namespaces.
* `payments`: Contains the `payments` namespaces.

The `payments` service is configured to introduce a 200ms latency, and the `checkout`
service is configured to fail 20% of the requests.  
The `eshop` ingress gateway is also
configured to rate-limit to a max of 3 requests per second per unique client address.   
Hierarchical policies are set to limit access to the `payments` application from the `checkout`
security group.

![eshop-topology](topology.png)

By default, it uses a demo LDAP as the Identity provider, and the following users
are configured. However, custom users can be designated as owners of the different applications
by configuring the environment variables as explained in the table at the end.

* `nacx/nacx-pass`: Is a Creator on the eshop tenant.
* `zack/zack-pass`: Is the owner of the eshop workspace.
* `wusheng/wusheng-pass`: Is the owner of the payments workspace.
