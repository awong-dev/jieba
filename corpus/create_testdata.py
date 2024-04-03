#!python

import pycantonese
import json

corpora = [
    "https://childes.talkbank.org/data/Biling/CHCC.zip",
    "https://childes.talkbank.org/data/Biling/Guthrie.zip",
    "https://childes.talkbank.org/data/Chinese/Cantonese/HKU.zip",
    "https://childes.talkbank.org/data/Chinese/Cantonese/LeeWongLeung.zip",
    "https://childes.talkbank.org/data/Biling/Leo.zip",
    "https://phonbank.talkbank.org/data/Chinese/Cantonese/PaidoCantonese.zip",
    "https://childes.talkbank.org/data/Biling/YipMatthews.zip"
]

def main():
    hkcancor = pycantonese.hkcancor()
    utt_by_files = hkcancor.utterances(by_files=True)

    segmentation_data = []
    for f in utt_by_files:
      for utt in f:
          segments = [ token.word for token in utt.tokens ]
          text = ''.join(segments)
          segmentation_data.append([text,segments])
    with open('./data/hkcancor_segmentation.json', 'w') as f:
        json.dump(segmentation_data, f)

if __name__ == '__main__':
    main()
