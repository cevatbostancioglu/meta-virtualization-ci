Project Decision:
=================

I choose my meta-virtualization-ci project for build pipeline. Reasons :

- I know the tooling, language limits, environment, practices. 
- CI structure was missing part of most of the yocto layers/BSPs. 
- My CI structure was just building images, there was no automated testing,
linter, deploy, artifact kind of features. I was just loosing too much
time. 
- Make that project structure done finally, everyone can add
tests/build steps easily.

CI Infrastructure Decision:
===========================

I choose Gitlab-CI for this assignment. Reasons: 

- I didn't use that before but i know it is very popular. I want to test/learn it. 
- Jenkins ci/cd infrastructures becomes plugin-hell pretty easily. Gitlab-ci logic
is one package. i dont have to install many plugins. 
- I don't want to use third-party, version based tools, one basic package tool is fine for
me.

What can i do decision:
=======================

-   I can create end to end ci solution with any free tool on market, if
    the tool was not usable in one way, we can just switch
    between tools.
-   I can mostly code in script files for testing, building, deploying
    then i can move ci structures between ci tools(jenkins, travis,
    gitlab-ci, etc.) if that is neccesary. There was a just little/none
    ci infrastructure porting.
-   I can build default qemu machines with default yocto setup and run
    my tests inside qemu machines. This feedback structure is works
    pretty well.
-   CI/CD related topics(artifacts, deploy, cache policy,
    commit-pr-merge triggers, caches) best practices can be learn
    from internet.
-   Some of the topics cannot/easily apply this project.(coverage)
-   Some of the topics maybe cannot done in given time, i can try to
    cover most of the important tasks.
-   Everything should be in code.
-   CI Infrastructure itself has to be easy
    to install/port/maintain/change.
-   This project has to be minimalist(minimum tools required) and code
    should be as symetric as possible. Use same kind of applications for
    solving problems, try avoid internal logics etc.

Information gathering:
======================

-   https://www.youtube.com/watch?v=6BIry0cepz4
-   https://www.youtube.com/watch?v=34u4wbeEYEo&list=PLaFCDlD-mVOlnL0f9rl3jyOHNdHU--vlJ
-   Continuous Integration: Improving Software Quality and Reducing Risk
    1st Edition
-   Continuous Delivery: Reliable Software Releases through Build, Test,
    and Deployment Automation (Addison-Wesley Signature Series (Fowler))
    1st Edition
-   Continuous Delivery with Docker and Jenkins: Delivering software at
    scale
-   https://docs.gitlab.com/ee/ci/README.html

Topics Coverage:
================

-   Linter: commit message check created. Json format checker created.
    branch-name check created and disabled. rob/sob is todo. spell-check
    has npm package(gommit etc) and aspell(ubuntu 16 default) program.
    spell checking is hard, software modules can contain meaningfull
    module names into commit messages. spell checking dictionary has to
    be defined for each project.
-   Cache: cache management is hard in yocto. i created global cache for
    build states/outputs/fetchs and everytime ci tool tries to copy them
    into build environment(normal) and this takes too much time. so for
    beginning, i created build caches/fetches outsite of
    build environment. I did all test/deploy jobs in that setup and then
    i understand what i need for cache management. After that i created
    cache management policy. cache policy is described in this document.
-   Tests: Running qemu(x86,arm) from yocto is easy. Yocto gives all
    kernel,rootfs,dts,network options/paths to qemu. The hard thing is
    running commands from console. I tried to use autoexpect tools with
    my test scripts but it doesn't worked. I moved to ssh for connection
    and i decide to use BATS(bash automated testing system) framework
    for testing. Otherwise it's hard to maintain. pipeline runs yocto
    runqemu function and tests are deployed over ssh when device is
    open, results are compared/reported at build-machine.
-   Maintain/Port/Track: everything in code basically. But logic is
    inside shell scripts. I just use basic inheritance between jobs.
    Project is using couple of environment variables from
    gitlab-ci infrastructure. Adding new machine/test/config is
    pretty easy.
-   Permissions: I have been trouble with permissions a lot for
    this project. I changed gitlab-runner user for my normal user, every
    cache is created by this user, i changed sudo access rights for user
    so i dont have to send password over cli. So there was minimal risk
    of access/freeze problems.
-   Communication: Created discord channel for ci. checkout:
    https://discord.gg/XAHkK8X
-   Environment: Everything is running with fresh ubuntu-16.04 setup, i
    created install scripts for installing what i need, yocto project
    requirements can change pretty easily, there was always maintainance
    cost for yocto latest versions. I did this because of time
    limitations, i have to just think my computer as docker environment.
    Yocto itself creates pretty good containerized solution so build
    artifacts don't use host tools except sed,awk,gawk kind of commands.
    But docker is still best option. checkout:
    https://docs.gitlab.com/runner/executors/README.html
-   Logs/artifacts: Device opening logs are stored as artifacts. Build
    outputs are stored as artifacts. For expire dates, please check
    Artifact management policy.
-   Aborting: Yocto build aborting can be pretty bad idea in
    scripted environment. I tried to block aborting couple of jobs in
    ci infrastructure. [ There was a issue about gitlab-ci configuration, interruption is not working properly. ]
-   Bottleneck: I tried to create cache mng. policy for speed up
    pipeline while outputs are still correct. Also tried to implement
    commit changes&decide to run logic for jobs. If commit is about
    documentation, we are not building yocto and not running tests.
-   Job Dependencies: Some jobs executation is dependent another jobs
    success, so we are not running unneccesary jobs.
-   docs: i created pdf files from md. pipeline also check spelling
    in md.

Cache management policy with branhing stragety and project requirements:
========================================================================

-   The issue is yocto downloads too much packages and builds them. If
    you use already builded package outputs with your code, you cant
    trust yocto for cache management. Using downloads is fine, caches
    can be risky. best solution is every branch should be use bitbake
    clean <your_package> to clean it with dependecies. For this setup,
    we are not working on spesific packages, we are just skipped clean
    step in ci structure.
-   feature/hotfix/fix/bug branches pull requests/commits will use
    /build/${ARCH}/${MACHINE}/global cache.
-   dev/dev pull requests will use /build/${ARCH}/${MACHINE}/dev cache.
-   master/master pull requests will use
    /build/${ARCH}/${MACHINE}/master cache. if tag is stable, clean all
    cache then run pipeline.
-   All branchs can use same download cache(only arch
    dependent, /build/\${ARCH}). Since they are just source code
    archives, they are well versioned.

Artifact management policy:
===========================

-   The issue is artifacts are very big size and you can store every
    commit artifact if you want. But it's not effective.
-   i tried to use never expire in gitlab-ci but gitlab-ci throw errors. so i just set expire date to 10 years.
-   feature/hotfix/fix/bug branchs pull requests/commits build artifacts
    will expire in 10 hour. Log artifacts expire 10 hour.
-   dev branchs artifacts will expire in 1 week. Log artifacts
    never expire.
-   master branch artifacts will never expire. Log artifacts
    never expire.

Issues:
=======

-   if qemu x86-arm machines try to run at the same time, they both try to get same ip addresses then test jobs failed. i disabled x86 builds since i am working on same machine. maybe yocto/runqemu patch can solve this error.
-   qemu machine running sometimes ends with write-lock problem. we are not cleaning resource effective, sometimes machine cannot close itself properly. 
-   gitlab-runner have problems with nohup outputs, because of qemu machine has to be in running state(background job), gitlab-runner cannot understand job is finished if jobs are running at background. docker cannot solve this but amd64-arm seperated dockers can contain systemd services, so gitlab-runner cannot check pids.

Focus on assignment:
====================

- I mostly focus to make this assignment end-to-end functoinal.

Timeline:
=========

- I started to working on this 5 days ago, 1 day reading/thinking and 4 day implementation. I worked 4-5 hours/day at weekday nights and 8-10 hours/day at weekend.

I wish to do:
=============

-   pipeline executaion with docker container.
-   credentials management.
-   github integration.
-   github release deployment with changelogs etc.
-   Performance measurement. ex: pipeline failed if performance -%10.
-   Product/development environment kind of setup. You can rollback
    machines etc.
-   code quality/coverage metrics. They are not common in yocto but
    maybe python linters will work.

My feedback on assignment:
==========================

-   Really nice interview approach.
