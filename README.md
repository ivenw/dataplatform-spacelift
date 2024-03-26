
# Style Guide

## Terraform

Where no guidance is given here, the [Terraform Best Practices](https://www.terraform-best-practices.com/)
should be followed.

The project is composed of two different types of modules, infrastructure modules (`stacks`)
and child modules (`modules`). `stacks` are Terraform root modules that serve as templates for the configuration
of stacks in Spacelift. `modules` are Terraform modules that abstract and compose common resource
configurations

The following rules apply to naming and project structure:
- `modules` should not call other modules, to ensure a clear and flat module hierarchy.
- Folder and file names are all-lowercaes with `-` sparingly used as a separator.
- `.tf` files should be formatted with [`terraform fmt`](https://developer.hashicorp.com/terraform/cli/commands/fmt)
before commited to the project.

## Resource naming

### Azure

For naming resources in Azure, we are following the
[Azure best practices for resource naming](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
with modifications.

The pattern we use is as follows:
```
<resource>-<application>-<workload>-<environment>-<region>-<hash>
```
Since many resources have name lenght restrictions, most of these fields are abbreviations
and the ones that are not have to be very concise.

Explanation:
- `<resource>` is taken from [here](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- `<appliction>` is an acronym of the application under which umbrella the resources fall. E.e. `dp` for
data platform.
- `<workload>` is a short description of the workload that the resource is fulfilling in the application
E.g. `integration` for a Azure Data Factory resource.
- `<environment>` is a three letter abbreviation of the environment (`dev`, `tst`, `prd`, etc.)
- `<region>` is a three letter geo code for the Azure region the resource is provisioned in, derived from [here](https://learn.microsoft.com/en-us/azure/backup/scripts/geo-code-list)
- `<hash>` are the first four characters of the md5 hash of the Subscription ID, `<application>`,
`<environment>`, and `<region>`.
Only used if the resource name needs to be globally unique.
- The instance is ommitted. In cases where multiple instances of a resource would need to be created
under the same workload in the same region, an incrementing number would be added to the workload.

Other rules:
- All characters have to be either ASCII letters or numbers. No special characters are allowed.
- Resources, like Storage Accounts, that don't allow for dashes in their name, have those removed.

These conventions are implemented and enforced in the `resource-name` module.


