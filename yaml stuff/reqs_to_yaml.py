import yaml

def requirements_to_yaml(requirements_file, yaml_file):
    dependencies = []
    
    with open(requirements_file, 'r') as f:
        for line in f:
            # Split each line into package and version
            if '==' in line:
                package, version = line.strip().split('==')
                dependencies.append({'package': package, 'version': version})
            else:
                dependencies.append({'package': line.strip(), 'version': None})

    with open(yaml_file, 'w') as f:
        yaml.dump({'dependencies': dependencies}, f, default_flow_style=False)
    
requirements_to_yaml('requirements.txt', 'environment.yaml')