'use strict'

module.exports = (grunt) ->
  # project configuration
  grunt.initConfig
    # load package information
    pkg: grunt.file.readJSON 'package.json'

    meta:
      banner: '/* ===========================================================\n' +
        '# <%= pkg.title || pkg.name %> - v<%= pkg.version %>\n' +
        '# ==============================================================\n' +
        '# Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.name %>\n' +
        '# Licensed <%= _.pluck(pkg.licenses, \"type\").join(\", \") %>.\n' +
        '*/\n'

    coffeelint:
      options: grunt.file.readJSON('node_modules/sphere-coffeelint/coffeelint.json')
      default: ['Gruntfile.coffee', 'src/**/*.coffee']

    clean:
      default: 'lib'
      test: 'test'

    coffee:
      options:
        bare: true
      default:
        files: grunt.file.expandMapping(['**/*.coffee'], 'lib/',
          flatten: false
          cwd: 'src/coffee'
          ext: '.js'
          rename: (dest, matchedSrcPath) ->
            dest + matchedSrcPath
          )
      test:
        files: grunt.file.expandMapping(['**/*.spec.coffee'], 'test/',
          flatten: false
          cwd: 'src/spec'
          ext: '.spec.js'
          rename: (dest, matchedSrcPath) ->
            dest + matchedSrcPath
          )
      testHelpers:
        files: grunt.file.expandMapping(['**/*Helper.coffee'], 'test/',
          flatten: false
          cwd: 'src/spec'
          ext: '.js'
          rename: (dest, matchedSrcPath) ->
            dest + matchedSrcPath
          )

    concat:
      options:
        banner: '<%= meta.banner %>'
        stripBanners: true
      default:
        expand: true
        flatten: true
        cwd: 'lib'
        src: ['*.js']
        dest: 'lib'
        ext: '.js'

    # watching for changes
    watch:
      run:
        files: ['Gruntfile.coffee', 'src/**/*.coffee']
        tasks: ['build', 'express']
        options:
          spawn: false # Without this option specified express won't be reloaded
      test:
        files: ['src/**/*.coffee']
        tasks: ['test']

    express:
      options:
        port: 3000
        showStack: true
      run:
        options:
          node_env: 'development'
          script: 'lib/app.js'
      test:
        options:
          node_env: 'test'
          script: "lib/app.js"

    shell:
      options:
        stdout: true
        stderr: true
        failOnError: true
      coverage:
        command: 'istanbul cover jasmine-node --captureExceptions test && cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js && rm -rf ./coverage'
      jasmine:
        command: 'jasmine-node --verbose --captureExceptions test'

    bump:
      options:
        files: ['package.json']
        updateConfigs: ['pkg']
        commit: true
        commitMessage: 'Bump version to %VERSION%'
        commitFiles: ['-a']
        createTag: true
        tagName: 'v%VERSION%'
        tagMessage: 'Version %VERSION%'
        push: true
        pushTo: 'origin'
        gitDescribeOptions: '--tags --always --abbrev=1 --dirty=-d'

  # load plugins that provide the tasks defined in the config
  grunt.loadNpmTasks 'grunt-bump'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-express-server'
  grunt.loadNpmTasks 'grunt-shell'

  # register tasks
  grunt.registerTask 'default', ['run']
  grunt.registerTask 'run', ['build', 'express:run', 'watch:run']
  grunt.registerTask 'build', ['clean', 'coffeelint', 'coffee', 'concat']
  grunt.registerTask 'test', ['build', 'express:test', 'shell:jasmine']
  grunt.registerTask 'coverage', ['build', 'express:test', 'shell:coverage']
  grunt.registerTask 'release', 'Release a new version, push it and publish it', (target) ->
    target = 'patch' unless target
    grunt.task.run "bump-only:#{target}", 'test', 'bump-commit'
