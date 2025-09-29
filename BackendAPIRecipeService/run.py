from src import create_app
import os
app = create_app()
if __name__ == '__main__':
    port = int(os.environ.get('PORT', '5000'))
    # DISABLE_RELOADER=1 disables Flask reloader; default is disabled for deterministic validation
    disable = os.environ.get('DISABLE_RELOADER', '1').lower() in ('1', 'true')
    app.run(host='0.0.0.0', port=port, use_reloader=(not disable), threaded=True)
