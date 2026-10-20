# Microsoft Learn Platform API

Small TypeScript client for the Microsoft Learn Platform API catalog, following the [official quickstart](https://learn.microsoft.com/en-us/training/support/integrations-learn-platform-api-catalog-quickstart).

## Prerequisites

- Node.js 18 or later
- Azure CLI signed in with an identity that can access the Learn Platform API

## Set up::

From this folder, install the dependencies and sign in if needed1:

```powershell
npm install
az login
```

If you have multiple Azure subscriptions, choose the active one with `az account set --subscription "<subscription-name-or-id>"`. The quickstart uses your identity for authentication and does not create billable Azure resources.

## Run

List beginner Azure certifications:

```powershell
npm start -- certifications --levels beginner --products azure --maxpagesize 5
```

List requests follow all pages automatically and print a compact table. Use `--maxitems` to cap the number returned, for example:

```powershell
npm start -- learning-paths --maxpagesize 5 --maxitems 10
```

List Spanish learning paths:

```powershell
npm start -- learning-paths --locale es-es --maxpagesize 5
```

Fetch a specific module:

```powershell
npm start -- modules learn.wwl.fundamentals-generative-ai
```

Supported list resources are `courses`, `learning-paths`, `modules`, `certifications`, `exams`, and `applied-skills`. Detail requests also support `units` and print formatted JSON. List filters are `levels`, `roles`, `products`, `subjects`, `locale`, `maxpagesize`, and `maxitems`.