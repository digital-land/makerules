# Digital Land makerules

# Updating a collection

We recommend working in a Python [virtual environment](http://docs.python-guide.org/en/latest/dev/virtualenvs/):

    $ make init
    $ make

# Licence

The software in this project is open source and covered by the [LICENSE.md](LICENSE.md) file.

# Developing against make targets that fetch from digital-land Github Repository

To run any make rules that fetch files from other repositories, it's helpful to have them fetch files from your filesystem by setting the `SOURCE_URL` argument explicitly as `file://$(dirname $pwd)`:

```
make SOURCE_URL=file://$(dirname $pwd)
```
