## 2018/02/25

* Moved base Docker image to Ubuntu Xenial.
* Upgraded Meteor to 1.6.0.1, which is the last version before
  CoffeeScript was removed from core packages which introduces
  issues with some package dependencies.
* Moved from using CLA to DCO and updated `CONTRIBUTING.md`.
  Now contributors by adding their e-mail address to `.gitauthors`
  certify they adhere to DCO.
  [#202](https://github.com/peer/mind/issues/202)
* Started a changelog in `HISTORY.md` file to document changes to the project in one place.
