from struct import unpack_from
import os

def readMIHU(filePath):
	class MIHUHeader:
		def __init__(self, data, off=0):
			(self.mihu_magic,
				self.mihu_version,
				self.hdrs_zeroing_cs8,
				self.num_images,
				self.total_len,
				self.target_pid,
				self.target_version) = unpack_from('IHBBIHH', data, off)		
		
		def __len__(self):
			return 16
	
	class ImageHeader:
		def __init__(self, data, off):
			(self.payload_offset,
			    self.payload_length,
			    self.hbpp_addr,
			    self.hbpp_chunk_size,
			    self.checksum16) = unpack_from('IIIHH', data, off)		
		
		def __len__(self):
			return 16
	
	with open(filePath, 'rb') as mihuFile:
		mihu = bytearray(mihuFile.read())
	
	off = 0
	header = MIHUHeader(mihu)
	off += len(header)
	images = []
	for i in range(header.num_images):
		imageHeader = ImageHeader(mihu, off)
		off += len(imageHeader)
		version = os.path.basename(filePath).split('-')[2]
		version = version.split('.')[0]
		images.append({
			'Type': 'Binary',            
			'Payload': mihu[imageHeader.payload_offset:(imageHeader.payload_offset+imageHeader.payload_length)],
			'Address': imageHeader.hbpp_addr,
            'MaxSize': imageHeader.payload_length,
			'Description': '{:s} ({:d}/{:d})'.format(version, i + 1, header.num_images),
		})
	return images			

