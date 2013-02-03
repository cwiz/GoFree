# coding: utf-8

from optparse import OptionParser
from pymorphy import get_morph

import sys
import chardet



parser = OptionParser()
parser.add_option("-w", "--word", 
	dest	= "word",
	metavar	= "WORD"
)

parser.add_option("-d", "--dicts", 
	dest	= "dict",
	metavar	= "DICT"
)


def main():
	(options, args) = parser.parse_args()

	if not options.word or not options.dict:
		print 'inflect -h for help.'
		return
		
	morph = get_morph(options.dict)

	word 	= options.word.decode(chardet.detect(options.word)['encoding']).upper()
	word 	= unicode(word)

	a 		= morph.inflect_ru(word, u'пр', u'С')
	print a.encode('utf8')

main()


