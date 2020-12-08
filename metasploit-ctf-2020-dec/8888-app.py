#----------------------------------------------------------------------------#
# Imports
#----------------------------------------------------------------------------#
import config
from flask import Flask, Markup, abort, render_template, request, g
# from flask.ext.sqlalchemy import SQLAlchemy
import logging
from logging import Formatter, FileHandler
from forms import *
import base64
import os
import pathlib
import pickle
import json
import rule_engine

app_path = pathlib.Path(__file__).absolute().parent

with (app_path / 'modules_metadata_base.json').open('r') as file_h:
    msf_modules = json.load(file_h)
for module in msf_modules.values():
    module['platforms'] = tuple(platform.strip() for platform in set(module['platform'].split(',')))

with (app_path / 'flag.png').open('rb') as file_h:
    FLAG = file_h.read()
if not config.DEBUG:
    (app_path / 'flag.png').unlink()

rule_context = rule_engine.Context(type_resolver={
    'name': rule_engine.DataType.STRING,
    'fullname': rule_engine.DataType.STRING,
    'aliases': rule_engine.DataType.ARRAY(rule_engine.DataType.STRING),
    'rank': rule_engine.DataType.FLOAT,
    'type': rule_engine.DataType.STRING,
    'author': rule_engine.DataType.ARRAY(rule_engine.DataType.STRING),
    'description': rule_engine.DataType.STRING,
    'rport': rule_engine.DataType.FLOAT,
    'autofilter_ports': rule_engine.DataType.ARRAY(rule_engine.DataType.FLOAT),
    'check': rule_engine.DataType.BOOLEAN,
    'platforms': rule_engine.DataType.ARRAY(rule_engine.DataType.STRING),
    'ref_name': rule_engine.DataType.STRING
})

#----------------------------------------------------------------------------#
# App Config.
#----------------------------------------------------------------------------#

app = Flask(__name__)
app.config.from_object('config')
#db = SQLAlchemy(app)

# Automatically tear down SQLAlchemy.
'''
@app.teardown_request
def shutdown_session(exception=None):
    db_session.remove()
'''

# Login required decorator.
'''
def login_required(test):
    @wraps(test)
    def wrap(*args, **kwargs):
        if 'logged_in' in session:
            return test(*args, **kwargs)
        else:
            flash('You need to login first.')
            return redirect(url_for('login'))
    return wrap
'''

@app.before_request
def pre_yolo():
    session = {}
    if session_data := request.cookies.get('SESSION'):
        session.update(pickle.loads(base64.b64decode(session_data)))
    g.session = session

@app.after_request
def post_yolo(response):
    session_data = base64.b64encode(pickle.dumps(g.session))
    response.set_cookie('SESSION', session_data)
    return response

#----------------------------------------------------------------------------#
# Controllers.
#----------------------------------------------------------------------------#
@app.route('/')
def home():
    return render_template('pages/modules.html', modules=msf_modules.values())

@app.route('/module/<path:fullname>')
def module(fullname):
    module = next((module for module in msf_modules.values() if module.get('fullname') == fullname), None)
    if module is None:
        abort(404)
    return render_template('pages/module.html', module=module)

@app.route('/modules')
@app.route('/modules/<module_type>')
def modules(module_type=None):
    modules = tuple(msf_modules.values())
    if module_type is not None:
        modules = tuple(module for module in modules if module.get('type') == module_type)
    alert = None
    if filter_expresion := (request.args.get('filter') or g.session.get('filter')):
        # this whole thing is a red herring
        try:
            rule = rule_engine.Rule(filter_expresion, context=rule_context)
            modules = rule.filter(modules)
        except rule_engine.RuleSyntaxError:
            alert = 'The filter expression contained a syntax error.'
        except rule_engine.EngineError:
            alert = 'The filter expression contained an error.'
        else:
            g.session['filter'] = filter_expresion
    return render_template('pages/modules.html', alert=alert, modules=modules)

# Error handlers.
@app.errorhandler(500)
def internal_error(error):
    #db_session.rollback()
    alert = None
    if isinstance(error.original_exception, pickle.UnpicklingError):
        alert = Markup('There was an error while loading the SESSION cookie with <code>pickle.loads</code>.')
    return render_template('errors/500.html', alert=alert), 500

@app.errorhandler(404)
def not_found_error(error):
    return render_template('errors/404.html'), 404

if not app.debug:
    file_handler = FileHandler('error.log')
    file_handler.setFormatter(
        Formatter('%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]')
    )
    app.logger.setLevel(logging.INFO)
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)
    app.logger.info('errors')

#----------------------------------------------------------------------------#
# Launch.
#----------------------------------------------------------------------------#
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=config.HTTP_PORT)