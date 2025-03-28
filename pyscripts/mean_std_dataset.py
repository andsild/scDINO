import torch
from torchvision import datasets
import utils
from tifffile import imread
import numpy
import torchvision.transforms as transforms
from PIL import Image


class ReturnIndexDataset(datasets.ImageFolder):
        def __getitem__(self, idx):
            path, target = self.samples[idx]
            image = torch.from_numpy(numpy.array(Image.open(path))).permute(2, 0, 1)
            return image, idx

            # image= imread(path)
            # image=image.astype(float)
            # if snakemake.params['center_crop'] != 0:
            #     image = torch.from_numpy(image).permute(2, 0, 1)
            #     transform = transforms.CenterCrop(snakemake.params['center_crop'])
            #     tensor = transform(image)
            #     image = image.permute(1, 2, 0)
            #     image = image.numpy()
            # image = utils.normalize_numpy_0_to_1(image)
            # if utils.check_nan(image):
            #     print("nan in image: ", path)
            #     return None
            # else:
            #     tensor = torch.from_numpy(image).permute(2, 0, 1)
            #     if torch.isnan(tensor).any():
            #         print("nan in tensor: ", path)
            #         return None
            #     else:
            #         return tensor, idx

def collate_fn(batch):
    batch = list(filter(lambda x: x is not None, batch))
    return torch.utils.data.dataloader.default_collate(batch)

print("loading dataset...")
dataset_total = ReturnIndexDataset(snakemake.params["data_dir"])
print("length of dataset: ", len(dataset_total))

#SAMPLER SECTION
validation_split = 1-float(snakemake.params["fraction_for_mean_std"])
shuffle_dataset = True
random_seed= 42
dataset_size = len(dataset_total)
indices = list(range(dataset_size))
split = int(numpy.floor(validation_split * dataset_size))
if shuffle_dataset :
    numpy.random.seed(random_seed)
    numpy.random.shuffle(indices)
train_indices, val_indices = indices[split:], indices[:split]

print(len(train_indices), len(val_indices))

print(f"Train dataset consists of {len(train_indices)} images.")

train_sampler = torch.utils.data.SubsetRandomSampler(train_indices)

image_data_loader = torch.utils.data.DataLoader(
    dataset_total,
    sampler=train_sampler,
    batch_size=int(len(train_indices)/10),
    #batch_size=32,
    num_workers=0, 
    collate_fn=collate_fn, 
    drop_last=True)

print("Successfully loaded data.")

def batch_mean_and_sd(loader):
    cnt = 0
    picture, _ = next(iter(image_data_loader))
    b, c, h, w = picture.shape
    fst_moment = torch.empty(c)
    snd_moment = torch.empty(c)
    
    for images, _ in loader:
        b, c, h, w = images.shape
        nb_pixels = b * h * w
        sum_ = torch.sum(images, dim=[0, 2, 3])
        sum_of_square = torch.sum(images ** 2,
                                  dim=[0, 2, 3])
        fst_moment = (cnt * fst_moment + sum_) / (cnt + nb_pixels)
        snd_moment = (cnt * snd_moment + sum_of_square) / (cnt + nb_pixels)
        cnt += nb_pixels

    mean, std = fst_moment, torch.sqrt((snd_moment - fst_moment) ** 2)
    return mean,std
  
mean, std = batch_mean_and_sd(image_data_loader)
print("mean and std: \n", mean, std)
import json
with open(snakemake.output[0], 'w') as f:
    json.dump({"mean": mean.tolist(), "std": std.tolist()}, f)
