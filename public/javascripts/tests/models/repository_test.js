describe('Models:', function() {
  describe('Repository', function() {
    beforeEach(function() {
      this.repositories = new Travis.Collections.Repositories(INIT_DATA.repositories);
      this.repository = this.repositories.models[1];
    });

    it('an initial repository holds the expected attributes', function() {
      expectAttributes(this.repository, {
        name: 'minimal',
        url: 'https://github.com/svenfuchs/minimal',
        last_duration: 10
      });
      expectAttributes(this.repository.user, {
        login: 'svenfuchs'
      })
    });

    it('has a builds collection', function() {
      expectAttributes(this.repository.builds.models[0], {
        commit: 'add057e66c3e1d59ef1f',
        log: 'minimal build 3 log ...',
        message: 'unignore Gemfile.lock',
        number: 3,
        started_at: '2010-11-12T13:00:00Z'
      });
    });

    it('does not hold a last_build attribute (but adds it to the builds collection)', function() {
      expect(this.repository.attributes.last_build).toBeUndefined();
    });

    describe('set', function() {
      it('sets the last_build attribute to the builds collection', function() {
        var buildId = this.repository.builds.models[0].get('id');
        this.repository.set({ last_build: { id: buildId, commit: '123456' } });
        expect(this.repository.builds.get(buildId).get('commit')).toEqual('123456');
      });
    });

    it('delegates isBuilding to its last build', function() {
      expect(this.repository.isBuilding()).toBeTruthy();
      this.repository.builds.models.pop();
      expect(this.repository.isBuilding()).toBeFalsy();
    });

    it('toJSON returns the expected data', function() {
      expectProperties(this.repository.toJSON(), {
        name: 'minimal',
        url: 'https://github.com/svenfuchs/minimal',
        last_duration: 10,
        user: {
          login: 'svenfuchs'
        }
      });
    });

    describe('change events', function() {
      it('triggers a "change" event on the repository when a last_duration attribute is passed', function() {
        expectTriggered(this.repository, 'change', function() {
          this.repository.set({ last_duration: 20 })
        }.bind(this));
      });

      it('triggers a "change" event on the build when a finished_at attribute for that build is passed', function() {
        var build = this.repository.builds.last();
        expectTriggered(build, 'change', function() {
          this.repository.set({ last_build: { id: build.id, finished_at: new Date } })
        }.bind(this));
      });

      it('does not trigger a "change" event on the repository when only a last_build attribute is passed', function() {
        var build = this.repository.builds.last();
        expectNotTriggered(this.repository, 'change', function() {
          this.repository.set({ last_build: { id: build.id, finished_at: new Date } })
        }.bind(this));
      });
    });

    describe('builds add event', function() {
      it('triggers build:add on the collection', function() {
        expectTriggered(this.repositories, 'build:add', function() {
          this.repository.builds.add({ number: 2 });
        }.bind(this));
      });

      it('triggers build:add on the repository', function() {
        expectTriggered(this.repository, 'build:add', function() {
          this.repository.builds.add({ number: 2 });
        }.bind(this));
      });
    });

    describe('build change event', function() {
      it('triggers build:change on the collection', function() {
        expectTriggered(this.repositories, 'build:change', function() {
          this.repository.builds.models[0].change();
        }.bind(this));
      });

      it('trigger build:change on the repository', function() {
        expectTriggered(this.repository, 'build:change', function() {
          this.repository.builds.models[0].change();
        }.bind(this));
      });
    });
  });
});

