from setuptools import setup

setup(
    name='nixhome',
    version='0.1.0',
    py_modules=['nixhome'], # because this is a single-file script
    install_requires=['pyyaml'],
    entry_points={
        'console_scripts': [
            'nh = nixhome:main'
        ]
    }
)
