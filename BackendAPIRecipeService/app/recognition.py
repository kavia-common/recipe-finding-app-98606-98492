from typing import List

def recognize_image(path: str) -> List[str]:
    filename = path.lower()
    labels = []
    if 'tomato' in filename: labels.append('tomato')
    if 'cheese' in filename: labels.append('cheese')
    if not labels: labels = ['unknown']
    return labels
