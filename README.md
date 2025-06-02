# apisix-userinfo-decoder

### Decode `X-Userinfo` header from Base64 into separate headers


The headers created by this plugin are completely dynamic.
As long as you know the structure of the Userinfo object, you can extract any field and map it to a custom `X-*` header.

**ATTENTION:**
This plugin must be used in combination with the built-in `openid-connect` plugin in Apache APISIX.

---

## How to Use

There are multiple ways to use this plugin.

### 1. Install the Plugin

#### On Device

If you're running Apache APISIX on bare metal, simply place the `userinfo-decoder.lua` file into the `/usr/local/apisix/apisix/plugins` folder.

**NOTE:**
Don't forget to restart the Apache APISIX after following all steps using `apisix restart`

#### Docker

If you're running Apache APISIX inside a Docker container, you’ll need to mount the `userinfo-decoder.lua` file into the plugins folder.

You can do this by adding a volume mount:

```bash
./path/to/userinfo-decoder.lua:/usr/local/apisix/apisix/plugins/userinfo-decoder.lua
```

**NOTE:**
Don't forget to restart the container after you followed all steps.

### 2. Configure

With the plugin installed, we need to tell Apache APISIX how to use it.

In this example, we’ll use the [standalone configuration](https://apisix.apache.org/docs/apisix/deployment-modes/#standalone).

First, enable the plugin by adding it to the `plugins` list in your `config.yaml` file (note: `openid-connect` is also required):

```yaml
plugins:
  - openid-connect
  - userinfo-decoder
```

To avoid configuring the plugins on every individual route, we’ll define a reusable plugin configuration in `apisix.yaml`:

```yaml
plugin_configs:
  - id: auth
    plugins:
      openid-connect:
        client_id: my-client-id
        client_secret: mysupersecretclientsecret
        discovery: http://example.com/path/to/.well-known/openid-configuration  # URL to the .well-known/openid-configuration of your OIDC service
        scope: openid  # Add more scopes if required/configured
        bearer_only: true
        use_jwks: true  # For validating the JWT authentication token
        set_userinfo_header: true
      userinfo-decoder:
        headers:
          - User: "$userinfo.preferred_username"    # Sets the X-User header with the 'preferred_username'
          - Roles: "$userinfo.roles"                # Sets the X-Roles header with the 'roles'
```

Example UserInfo object:
```json
{
  "sub": "248289761001",
  "name": "Jane Doe",
  "preferred_username": "jane.doe",
  "given_name": "Jane",
  "family_name": "Doe",
  "email": "jane.doe@example.com",
  "email_verified": true,
  "roles": ["admin", "user"]
}
```
**Note:**
The structure of the Userinfo object depends on your OpenID Connect provider. The example above is a common format, but you should verify the exact fields your provider returns by querying the `/userinfo` endpoint or checking their documentation.

**(You can fully customize the `openid-connect` settings to your needs. For more details, refer to the [OpenID Connect plugin documentation](https://apisix.apache.org/docs/apisix/plugins/openid-connect/).)**

### 3. Result
Once everything is set up correctly:
* The `openid-connect` plugin will authenticate incoming requests and attach the `X-Userinfo` header.

* This plugin will decode the `X-Userinfo` (Base64-encoded JSON) and extract specific fields into new headers (e.g., `X-User`, `X-Roles`, etc.).

* These headers can then be consumed by your upstream services.

You can customize the output headers based on the structure of the userinfo JSON returned by your identity provider.

---

## Troubleshooting
Make sure `set_userinfo_header: true` is enabled in the `openid-connect` plugin.

Ensure the `X-Userinfo` header is being set. Check request logs or use a debugging tool like curl or Postman.

Verify your Lua file is placed correctly and that the plugin name matches the one listed in `config.yaml`.

---

## License

This plugin is licensed under the MIT license