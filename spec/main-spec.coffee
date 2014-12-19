describe 'Main Loader', ->

  describe 'before activation', ->
    it "settings aren't defined", ->
      expect(atom.config.getSettings()['MavensMate-Atom']).toBeUndefined()

    it "isn't activated", ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()

  describe 'after activation', ->

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage 'MavensMate-Atom'

    it 'to be activated', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeDefined()

    it 'settings are defined', ->
      expect(atom.config.getSettings()['MavensMate-Atom']).toBeDefined()
      config = atom.config.getSettings()['MavensMate-Atom']
      expect(config.mm_timeout).toBeDefined()
      expect(config.mm_developer_mode).toBeDefined()
      expect(config.mm_community_api_token).toBeDefined()
      expect(config.mm_use_keyring).toBeDefined()
      expect(config.mm_beta_user).toBeDefined()
      expect(config.mm_api_version).toBeDefined()
      expect(config.mm_log_location).toBeDefined()
      expect(config.mm_log_level).toBeDefined()
      expect(config.mm_workspace).toBeDefined()
      expect(config.mm_open_project_on_create).toBeDefined()
      expect(config.mm_http_proxy).toBeDefined()
      expect(config.mm_https_proxy).toBeDefined()
      expect(config.mm_play_sounds).toBeDefined()
      expect(config.mm_panel_height).toBeDefined()
      expect(config.mm_close_panel_on_successful_operation).toBeDefined()
      expect(config.mm_close_panel_delay).toBeDefined()
      expect(config.mm_template_location).toBeDefined()
      expect(config.mm_template_source).toBeDefined()
      expect(config.mm_default_subscription).toBeDefined()
      expect(config.mm_atom_exec_osx).toBeDefined()
      expect(config.mm_atom_exec_win).toBeDefined()
      expect(config.mm_atom_exec_linux).toBeDefined()
      expect(config.mm_ignore_managed_metadata).toBeDefined()
      expect(config.mm_use_org_metadata_for_completions).toBeDefined()
      expect(config.mm_apex_file_extensions).toBeDefined()
     